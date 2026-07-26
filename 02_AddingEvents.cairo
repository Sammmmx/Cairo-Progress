```cairo
#[starknet::interface] 
  trait IMessenger<TContractState> { 
  fn set_message (ref self: TContractState, input_message: ByteArray); 
  fn get_message (self: @TContractState) -> ByteArray; 
  }

#[starknet::contract] 
  mod Messenger { 
  #[storage] struct Storage { 
    owner: ContractAddress, message: ByteArray, 
    }
   
  #[event]
  #[derive(Drop, starknet::Event)]
  enum Event {
                MessageUpdated : MessageUpdated,                                     // New Event for when a new message is set.
  }                                                                                  

  #[derive(Drop, starknet::Event)]
  struct MessageUpdated {
                 #[key]
                 owner : ContractAddress,                                            // Records owner and the new message
                 new_message : ByteArray,
  }
       
  #[abi(embed_v0)]
  impl MessageModifier of super::IMessenger<ContractState> {
       fn set_message (ref self: ContractState, input_message: ByteArray)   {
          self.message.write(input_message.clone());

          self.emit(Event::MessageUpdated(MessageUpdated {
                   owner : get_caller_address(),
                   new_message : input_message,
          }));
       }       
                
       fn get_message (self: @ContractState) -> ByteArray {
          self.message.read()
       }
   }
}
```
