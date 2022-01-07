pragma solidity ^0.5.16;


contract KYCContract {
    address admin;

    /*
    Struct for a customer
     */
    struct Customer {
        string userName; //unique
        string data_hash; //unique
        uint256 rating;
        uint8 upvotes;
        address bank;
    }

    /*
    Struct for a Bank
     */
    struct Bank {
        string bankName;
        address ethAddress; //unique
        uint256 rating;
        uint8 kyc_count;
        string regNumber; //unique
    }

    /*
    Struct for a KYC Request
     */
    struct KYCRequest {
        string userName;
        string data_hash; //unique
        address bank;
        bool isAllowed;
    }


    mapping(string => Customer) customers;
    string[] customerNames;


    mapping(string => Customer) final_customers;
    string[] final_customerNames;

    /*
    Mapping a bank's address to the Bank Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(address => Bank) banks;
    address[] bankAddresses;

    
    mapping(string => KYCRequest) kycRequests;
    string[] customerDataList;

   
    mapping(string => mapping(address => uint256)) upvotes;

    constructor() public {
        admin = msg.sender;
    }

    
    function addKycRequest(string memory _userName, string memory _customerData)
        public
        returns (uint8)
    {
        // Check that the user's KYC has not been done before, the Bank is a valid bank and it is allowed to perform KYC.

        //checking if the bank is a vaid Bank

        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (msg.sender == bankAddresses[i]) {
                //checking if the customer KYC request alreay exist
                require(
                    !(kycRequests[_customerData].bank == msg.sender),
                    "This user already has a KYC request with same data in process."
                );
                kycRequests[_customerData].data_hash = _customerData;
                kycRequests[_customerData].userName = _userName;
                kycRequests[_customerData].bank = msg.sender;

                //incrementing the kyc_count for the bank
                banks[msg.sender].kyc_count++;

                //checking if the BANK is a trusted bank to add KYC requests
                if (banks[msg.sender].rating <= 50) {
                    kycRequests[_customerData].isAllowed = false;
                } else {
                    kycRequests[_customerData].isAllowed = true;
                }
                customerDataList.push(_customerData);
                return 1;
            }
        }
        return 0; // 0 is returned in case of failure
    }

   
    function addCustomer(string memory _userName, string memory _customerData)
        public
        returns (uint8)
    {
        //checking if the bank is a vaid Bank
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (msg.sender == bankAddresses[i]) {
                //checking if the customerdata hash is valid
                for (uint256 k = 0; k < customerDataList.length; k++) {
                    if (stringsEquals(customerDataList[k], _customerData)) {
                        require(
                            customers[_userName].bank == address(0),
                            "This customer is already present, modifyCustomer to edit the customer data"
                        );
                        require(
                            kycRequests[_customerData].isAllowed == true,
                            "isAllowed is false, bank is not trusted to perfrom the transaction"
                        );
                        customers[_userName].userName = _userName;
                        customers[_userName].data_hash = _customerData;
                        customers[_userName].bank = msg.sender;
                        customers[_userName].upvotes = 0;
                        customerNames.push(_userName);
                        return 1;
                    }
                }
            }
        }
        return 0; // 0 is returned in case of failure
    }

   
    function removeKYCRequest(
        string memory _userName,
        string memory customerData
    ) public returns (uint8) {
        uint8 i = 0;
        //checking if the provided username and customer Data are mapped in kycRequests
        require(
            (stringsEquals(kycRequests[customerData].userName, _userName)),
            "Please enter valid UserName and Customer Data Hash"
        );

        //looping through customerDataList and then deleting the kycRequests and deleting the customer data hash from customerDataList array
        for (i = 0; i < customerDataList.length; i++) {
            if (stringsEquals(customerDataList[i], customerData)) {
                delete kycRequests[customerData];
                for (uint256 j = i + 1; j < customerDataList.length; j++) {
                    customerDataList[j - 1] = customerDataList[j];
                }
                customerDataList.length--;
                return 1;
            }
        }
        return 0; // 0 is returned if no request with the input username is found.
    }

    
    function removeCustomer(string memory _userName) public returns (uint8) {
        //checking if the customer is present in the customers list
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], _userName)) {
                delete customers[_userName];
                //removing the customer from customerNames array
                for (uint256 j = i + 1; j < customerNames.length; j++) {
                    customerNames[j - 1] = customerNames[j];
                }
                customerNames.length--;
                return 1;
            }
        }
        return 0;
    }

    
    function viewCustomer(string memory _userName, string memory password)
        public
        view
        returns (string memory)
    {
        //looping through customerNames to check if the _userName passes is valid
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], _userName)) {
                //looping through passwordSet array, which is an string[] stores USERNAME's of user whose password is set
                //if password is set no changes are made to password, if not set then password is assigned a default value = '0'
                for (uint256 k = 0; k < passwordSet.length; k++) {
                    if (stringsEquals(passwordSet[k], _userName)) {
                        //no changes required
                        continue;
                    } else {
                        password = "0";
                    }
                }
            }
        }
        //passwordStore is a mapping of username=>password, if given username and password match we return customer data hash
        //else error is thrown informing user that password provided didn't match

        if (stringsEquals(passwordStore[_userName], password)) {
            return customers[_userName].data_hash;
        } else {
            return "password provided by the user didn't match";
        }
    }

    
    function upvoteCustomer(string memory _userName) public returns (uint8) {
        //checking if the customer exist in the customerNames
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], _userName)) {
                require(
                    upvotes[_userName][msg.sender] == 0,
                    "This bank have already upvoted this customer"
                );
                upvotes[_userName][msg.sender] = 1;
                customers[_userName].upvotes++;

                //updating the rating of the customer
                customers[_userName].rating =
                    (customers[_userName].upvotes * 100) /
                    bankAddresses.length;
                //if the customer rating is higher then also adding the customer to the final_customers list.
                if (customers[_userName].rating > 50) {
                    final_customers[_userName].userName = _userName;
                    final_customers[_userName].data_hash = customers[_userName]
                        .data_hash;
                    final_customers[_userName].rating = customers[_userName]
                        .rating;
                    final_customers[_userName].upvotes = customers[_userName]
                        .upvotes;
                    final_customers[_userName].bank = customers[_userName].bank;
                    //final_customerNames is array to itterate over customers
                    final_customerNames.push(_userName);
                }

                return 1;
            }
        }
        return 0;
    }

    
    function modifyCustomer(
        string memory _userName,
        string memory password,
        string memory _newcustomerData
    ) public returns (uint8) {
        //checking if the user exist
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], _userName)) {
                for (uint256 k = 0; k < passwordSet.length; k++) {
                    if (stringsEquals(passwordSet[k], _userName)) {
                        continue;
                    } else {
                        password = "0";
                    }
                }

                if (stringsEquals(passwordStore[_userName], password)) {
                    customers[_userName].data_hash = _newcustomerData;
                    customers[_userName].bank = msg.sender;
                    //after modifying customer data removing them from the final_customers list and final_customerNames array
                    for (uint8 j = 0; i < final_customerNames.length; j++) {
                        if (stringsEquals(final_customerNames[i], _userName)) {
                            delete final_customers[_userName];
                            customers[_userName].rating = 0;
                            customers[_userName].upvotes = 0;

                            for (
                                uint256 k = i + 1;
                                j < final_customerNames.length;
                                k++
                            ) {
                                final_customerNames[j -
                                    1] = final_customerNames[j];
                            }
                            final_customerNames.length--;
                        }
                    }
                    return 1;
                }
            }
        }
        return 0;
    }

    
    string[] KYC_UnValidatedCount;

    function getBankRequset(address bankAddress, uint256 index)
        public
        returns (
            string memory,
            string memory,
            address,
            bool
        )
    {
        //looping through bankAddresses array to check if the passed bankAddress is valid

        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == bankAddress) {
                //looping through customerDataList to find all the KYC requests initiated by the bank whose address is passed
                for (uint256 k = 0; k < customerDataList.length; k++) {
                    //kycRequests whose isAllowed value is False and bankAddress==bankAddress passed as Parameter
                    //store it in KYC_UnValidatedCount array.

                    if (
                        (kycRequests[customerDataList[k]].bank ==
                            bankAddress) &&
                        (kycRequests[customerDataList[k]].isAllowed == false)
                    ) {
                        KYC_UnValidatedCount.push(customerDataList[k]);
                    }
                }
            }
        }
        return (
            kycRequests[KYC_UnValidatedCount[index]].userName,
            kycRequests[KYC_UnValidatedCount[index]].data_hash,
            kycRequests[KYC_UnValidatedCount[index]].bank,
            kycRequests[KYC_UnValidatedCount[index]].isAllowed
        );
    }

    /*
	Upvotes to provide rating on other banks
	*/
    mapping(address => mapping(address => uint256)) upvotesBank;
    mapping(address => uint256) upvoteCount;

    function upvoteBank(address bankAddress) public returns (uint8) {
        //checking if the bank exist
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (msg.sender == bankAddresses[i]) {
                require(
                    upvotesBank[bankAddress][msg.sender] == 0,
                    "You have already upvoted this bank"
                );
                upvotesBank[bankAddress][msg.sender] = 1;
                upvoteCount[bankAddress]++;
                banks[bankAddress].rating =
                    (upvoteCount[bankAddress] * 100) /
                    bankAddresses.length;

                return 0;
            }
        }
        return 1;
    }

    /*
	Get customer rating
	*/

    function getCustomerRating(string memory userName)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], userName))
                return customers[userName].rating;
        }
    }

    /*
	Get bank Rating
	*/
    //checking if the bank exist
    function getBankRating(address bankAddress) public view returns (uint256) {
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == bankAddress) {
                return banks[bankAddress].rating;
            }
        }
    }

    /*
	Retrieve access history for a resource
	*/
    function retrieveHistory(string memory userName)
        public
        view
        returns (address)
    {
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], userName)) {
                return customers[userName].bank;
            }
        }
    }

    /*
	Set password
	*/
    //mapping of username to passwordStore
    mapping(string => string) public passwordStore;
    string[] public passwordSet;

    function setPassword(string memory userName, string memory password)
        public
        returns (bool)
    {
        //checking if the user exist
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], userName)) {
                passwordStore[userName] = password;
                //adding username to passwordSet array to itterate over user whose passwords are set
                passwordSet.push(userName);
                return true;
            }
        }
    }

    /*
	Get Bank Details
	*/
    function getBankDetail(address bankAddress)
        public
        view
        returns (
            string memory,
            address,
            uint256,
            uint8,
            string memory
        )
    {
        //checking if bank exist
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == bankAddress) {
                return (
                    banks[bankAddress].bankName,
                    banks[bankAddress].ethAddress,
                    banks[bankAddress].rating,
                    banks[bankAddress].kyc_count,
                    banks[bankAddress].regNumber
                );
            }
        }
    }

    
    function addBank(
        string memory bankName,
        address bankAddress,
        string memory bankRegistration
    ) public returns (string memory) {
        //checking if the account used to perform add operation is an Admin
        require(msg.sender == admin, "You are not an admin");
        require(
            banks[bankAddress].ethAddress == address(0),
            "This bank is already added to the samrt contract"
        );
        
        //adding bank
        banks[bankAddress].bankName = bankName;
        banks[bankAddress].ethAddress = bankAddress;
        banks[bankAddress].rating = 0;
        banks[bankAddress].kyc_count = 0;
        banks[bankAddress].regNumber = bankRegistration;
        bankAddresses.push(bankAddress);
        
        return "successful entry of bank to the contract";
    }

    
    function removeBank(address bankAddress) public returns (string memory) {
        //checking if the account used to perform remove operation is an Admin
        require(msg.sender == admin, "You are not an admin");
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == bankAddress) {
                delete banks[bankAddress];
                for (uint256 j = i + 1; j < bankAddresses.length; j++) {
                    bankAddresses[j - 1] = bankAddresses[j];
                }
                bankAddresses.length--;
                return "successful removal of the bank from the contract.";
            }
        }

        return "The bank is already removed from the contract";
    }

    
    function stringsEquals(string storage _a, string memory _b)
        internal
        view
        returns (bool)
    {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length) return false;
        // @todo unroll this loop
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }
}
