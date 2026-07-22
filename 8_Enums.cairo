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
    fn set_status(ref self: TContractState, end_time: u64, winner: ContractAddress);
    fn get_auction_status(self: @TContractState) -> u64;
}

#[starknet::contract]
mod Messenger {
    use starknet::get_caller_address;
    use starknet::ContractAddress; 
    use starknet::storage::Map;   
    use starknet::storage::Vec;      
    use starknet::contract_address_const;
    use starknet::get_block_timestamp;                                                                // Added new timestamp

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
    enum AuctionState {                                                       // New Auction Enum
         NotStarted,                                                  
         Active: u64,                                                    // Holds end timestamp
         Ended: ContractAddress,                                         // Holds Winner Address
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.owner.write(get_caller_address());
    }

    #[abi(embed_v0)]
    impl MessageModifier of super::IMessenger<ContractState> {
        fn set_message(ref self: ContractState, input_message: ByteArray) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(owner == caller, 'Not Owner');

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
            assert (amount > 0, 'Zero Value');

            let caller = get_caller_address();     
            let old = self.balances.entry(caller).read();
            let new_balance = old + amount;
            self.balances.entry(caller).write(new_balance);   
        }

        fn get_balance(self: @ContractState) -> u256 {                                                          
            self.balances.entry(get_caller_address()).read()
        }

        fn approve(ref self: ContractState, permit: ContractAddress, amount: u256) {                        
            assert (amount > 0, 'Zero Value');
     
            self.allowances.entry(get_caller_address()).entry(permit).write(amount);                        
        }

        fn get_allowance(self: @ContractState, permitted: ContractAddress) -> u256 {                        
            self.allowances.entry(get_caller_address()).entry(permitted).read()
        }

        fn add_to_whitelist(ref self: ContractState, member: ContractAddress) {                     
            assert(self.owner.read() == get_caller_address(), 'Not owner');                         
          
            let len = self.whitelist.len();
            let mut exist = false;
            let mut i: u64 = 0;
            loop {
              if i >= len {
                 break;
              }

              if self.whitelist.at(i).read() == member {
                 exist = true;
                 break;
              }
              i += 1;
            };
            assert(exist == false, 'Already whitelisted');                                       
          
            self.whitelist.append().write(member);
        }

        fn get_whitelisted(self: @ContractState, index: u64) -> ContractAddress {                   
            assert(index < self.whitelist.len(), 'Invalid index');
          
            self.whitelist.at(index).read()
        }

        fn set_status (ref self: ContractState, end_time: u64) {        // New Function to write Active and Ended enum values
            assert (self.owner.read() == get_caller_address(), 'Not owner');
            assert (end_time > get_block_timestamp(), 'Invalid Time');

            self.auctionState.write(AuctionState::Active(end_time));
        }

        fn get_auction_status(self: @ContractState) -> u64 {                                     // New Function to read auctionState values
            match self.auction_state.read() {
                  AuctionState::Active(_) => 'Auction is live',
                  _ => 0,
            }
        }
    }
}
