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
       
  #[abi(embed_v0)]
  impl MessageModifier of super::IMessenger<ContractState> {
       fn set_message (ref self: ContractState, input_message: ByteArray)   {
          self.message.write(input_message);
       }       
                
       fn get_message (self: @ContractState) -> ByteArray {
          self.message.read()
       }
   }
}
```
