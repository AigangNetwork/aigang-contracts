# Address Manager

**Events**
- Added(uint _typeId, address _contractAddress)
- ChangedStatus(uint _typeId, uint _index, uint8 _status);

**Functions**

* **contracts**
Holds all contracts addresses stored by types. Type Id depends on Organizer and is needed for Web application configuration to render items correctly. 

* **add(uint _typeId, address _contractAddress)**
Function to add already deployed contract.  
Ex: Type - 1 Prediction market contracts, Type 2 - Pools contracts. After adding contract WEB platform will display an item automatically.

* **get(uint _typeId, uint _index)**
Gets contract address by type at specific location. This function is used for paging.

* **getLength(uint _typeId)**
Gets length of contracts by type Id. This function is used for paging.

* **changeStatus(uint _typeId, uint _index, uint8 _status)**
Owner can specify the status of contract.  
Ex: Status - 2 canceled, and these items will be not displayed in the Web app.  