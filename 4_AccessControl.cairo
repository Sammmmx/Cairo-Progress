```cairo
#[starknet::interface] 
  trait IMessenger<TContractState> { 
  fn set_message (ref self: TContractState, input_message: ByteArray); 
  fn get_message (self: @TContractState) -> ByteArray; 
  }
#[starknet::contract] 
  mod Messenger { 
  #[storage] struct Storage { 
    owner: ContractAddress, 
    message: ByteArray, 
    }
   
  #[event]
  #[derive(Drop, starknet::Event)]
  enum Event {
       MessageUpdated : MessageUpdated,
  }
  #[derive(Drop, starknet::Event)]
  struct MessageUpdated {
         #[key]
         owner : ContractAddress,
         new_message : ByteArray,
  }
  #[constructor]
  fn constructor(ref self: ContractState) {                                
     self.owner.write(get_caller_address());
  }
       
  #[abi(embed_v0)]
  impl MessageModifier of super::IMessenger<ContractState> {
       fn set_message (ref self: ContractState, input_message: ByteArray)   {
          let caller = get_caller_address();                                                           // Owner check Access Control
          let owner = self.owner.read()
          assert(owner == caller, 'Not Owner')
            
          self.message.write(input_message.clone());
          self.emit(Event::MessageUpdated(MessageUpdated {
                   owner : caller,
                   new_message : input_message,
          }));
       }       
                
       fn get_message (self: @ContractState) -> ByteArray {
          self.message.read()
       }
   }
}
```
