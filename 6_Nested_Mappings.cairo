```cairo
#[starknet::interface]
trait IMessenger<TContractState> {
    fn set_message(ref self: TContractState, input_message: ByteArray);
    fn get_message(self: @TContractState) -> ByteArray;
    fn deposit(ref self: TContractState, amount: u256);                                                
    fn get_balance(self: @TContractState) -> u256;  
    fn approve(ref self: TContractState, permit: ContractAddress, amount: u256);                          // New Function to approve transfer to a specific address
    fn get_allowance(self : @TContractState, permitted: ContractAddress) -> u256;                                                     // New Function to read the approved balance to an address by the caller
}

#[starknet::contract]
mod Messenger {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::storage::Map;                                                                        

    #[storage]
    struct Storage {
        owner: ContractAddress,
        message: ByteArray,
        balances: Map<ContractAddress, u256>, 
        allowances: Map<ContractAddress, Map<ContractAddress, u256>>,                                    // New Map to store allowances
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

        fn approve(ref self: ContractState, permit: ContractAddress, amount: u256) {                                 // Allowing an address to transfer funds
            self.allowances.entry(get_caller_address()).entry(permit).write(amount);
        }

        fn get_allowance(self: @ContractState, permitted: ContractAddress) -> u256 {                               // Reading the allowed funds for transfer to an address
            self.allowances.entry(get_caller_address()).entry(permitted).read()
        }
    }
}
```
