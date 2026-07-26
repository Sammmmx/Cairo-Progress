use starknet::ContractAddress;

#[starknet::interface]
trait IMessenger<TContractState> {
    fn set_message(ref self: TContractState, input_message: ByteArray);
    fn get_message(self: @TContractState) -> ByteArray;
    fn deposit(ref self: TContractState, amount: u256);                                                
    fn get_balance(self: @TContractState) -> u256;  
    fn approve(ref self: TContractState, permit: ContractAddress, amount: u256);                         
    fn get_allowance(self : @TContractState, permitted: ContractAddress) -> u256;
    fn add_to_whitelist(ref self: TContractState, member: ContractAddress);                             
    fn get_whitelisted(self: @TContractState, index: u64) -> ContractAddress;       
    fn set_status(ref self: TContractState, end_time: u64);
    fn get_auction_status(self: @TContractState) -> felt252;
}

#[starknet::contract]
mod Messenger {
    use starknet::get_caller_address;
    use starknet::ContractAddress; 
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry};   
    use starknet::storage::Vec;      
    use starknet::contract_address_const;
    use starknet::get_block_timestamp; 
    use starknet::storage::StoragePointerReadAccess;   
    use starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::VecTrait;
    use starknet::storage::MutableVecTrait;

    #[derive(Drop)]
    enum MessengerError {                                          // 5 errors throughout the contract introduced as custom errors
        NotOwner,
        InvalidTime,
        ZeroValue,
        InvalidIndex,
        AlreadyWhitelisted,
    }

    #[storage]
    struct Storage {
        owner: ContractAddress,
        message: ByteArray,
        balances: Map<ContractAddress, u256>, 
        allowances: Map<ContractAddress, Map<ContractAddress, u256>>, 
        whitelist: Vec<ContractAddress>,   
        auction_state: AuctionState,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MessageUpdated: MessageUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct MessageUpdated {
        #[key]
        owner: ContractAddress,
        new_message: ByteArray,
    }

    #[derive(Drop, starknet::Store)]                         
    enum AuctionState {                                                       
         NotStarted,                                                  
         Active: u64,                                                    
         Ended: ContractAddress,                                         
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.owner.write(get_caller_address());
        self.auction_state.write(AuctionState::NotStarted);
    }

    impl MessengerErrorIntoFelt252 of Into<MessengerError, felt252> {                        // Setting the custom errors in felt252 for easy use
      fn into(self: MessengerError) -> felt252 {
        match self {
            MessengerError::NotOwner => 'Not Owner',
            MessengerError::InvalidTime => 'Invalid Time',
            MessengerError::ZeroValue => 'Zero Value',
            MessengerError::InvalidIndex => 'Invalid Index',
            MessengerError::AlreadyWhitelisted => 'Already Whitelisted',
        }
      }
    }

    #[abi(embed_v0)]
    impl MessageModifier of super::IMessenger<ContractState> {
        fn set_message(ref self: ContractState, input_message: ByteArray) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(owner == caller, MessengerError::NotOwner.into());

            self.message.write(input_message.clone());
            self.emit(Event::MessageUpdated(MessageUpdated {
                owner: caller,
                new_message: input_message,
            }));
        }

        fn get_message(self: @ContractState) -> ByteArray {
            self.message.read()
        }

        fn deposit(ref self: ContractState, amount: u256) {                                                       
            assert (amount > 0, MessengerError::ZeroValue.into());

            let caller = get_caller_address();     
            let old = self.balances.entry(caller).read();
            let new_balance = old + amount;
            self.balances.entry(caller).write(new_balance);   
        }

        fn get_balance(self: @ContractState) -> u256 {                                                          
            self.balances.entry(get_caller_address()).read()
        }

        fn approve(ref self: ContractState, permit: ContractAddress, amount: u256) {                        
            assert (amount > 0, MessengerError::ZeroValue.into());
     
            self.allowances.entry(get_caller_address()).entry(permit).write(amount);                        
        }

        fn get_allowance(self: @ContractState, permitted: ContractAddress) -> u256 {                        
            self.allowances.entry(get_caller_address()).entry(permitted).read()
        }

        fn add_to_whitelist(ref self: ContractState, member: ContractAddress) {                     
            assert(self.owner.read() == get_caller_address(), MessengerError::NotOwner.into());                         
          
            let len = self.whitelist.len();
            let mut exist = false;
            let mut i: u64 = 0;
            while i < len {
                if self.whitelist.at(i).read() == member {
                exist = true;
                break;
                }
            i += 1;
            };
            assert(!exist, MessengerError::AlreadyWhitelisted.into());

            self.whitelist.append().write(member);
        }

        fn get_whitelisted(self: @ContractState, index: u64) -> ContractAddress {                   
            assert(index < self.whitelist.len(), MessengerError::InvalidIndex.into());
          
            self.whitelist.at(index).read()
        }

        fn set_status(ref self: ContractState, end_time: u64) {        
            assert (self.owner.read() == get_caller_address(), MessengerError::NotOwner.into());
            assert (end_time > get_block_timestamp(), MessengerError::InvalidTime.into());

            self.auction_state.write(AuctionState::Active(end_time));
        }

        fn get_auction_status(self: @ContractState) -> felt252 {                                     
            match self.auction_state.read() {
                AuctionState::NotStarted => 'Not Started',
                AuctionState::Active(_) => 'Active',
                AuctionState::Ended(_) => 'Ended',
            }
        }
    }
}
