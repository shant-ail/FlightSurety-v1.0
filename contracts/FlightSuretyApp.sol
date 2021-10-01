pragma solidity >=0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    
    FlightSuretyData flightSuretyData;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;       // Account used to deploy contract

    mapping(address => uint256) authorizedContracts;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        string flightName;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

 
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
         // Modify to call data contract's status
        require(true, "Contract is currently not operational");  
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }



    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address dataContract
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            public 
                            pure 
                            returns(bool) 
    {
        return true;  // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline(string calldata airlineName) external payable
    {
        require(msg.value >= REGISTRATION_FEE, "Registration Fee is required");
        flightSuretyData.registerAirline(msg.sender, airlineName);
    }

    /**
    * @dev Retrieves an airline added in the system.
    *
    */ 

    function getAirline() external returns(bool, string memory, uint256)
    {
        bool isRegistered;
        string memory airlineName;
        uint256 balance;

        (isRegistered, airlineName, balance) = flightSuretyData.getAirline(msg.sender);
        return (isRegistered, airlineName, balance);
    }

    /**
    * @dev Function for collecting Ether for Voting Rights.
    *
    */

    function fund() public payable
    {
        require(msg.value >= 10 ether, "Minimum 10 Ether is required.");
        flightSuretyData.fund.value(msg.value)(msg.sender);
    }

   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                (
                                    string calldata flightNameReg,
                                    uint256 timestamp
                                )
                                external
    {
        bytes32 key = keccak256(abi.encodePacked(msg.sender, flightNameReg, timestamp));
        flights[key] = Flight({
            isRegistered: true,
            statusCode: 0,
            flightName: flightNameReg,
            updatedTimestamp: timestamp,
            airline: msg.sender
        });
    }

    /**
    * @dev Retrieves a Registered Flight.
    *
    */

    function getFlight(string calldata flightName, uint256 timestamp) external view returns (bool, uint8, string memory, uint256, address)
    {
        bytes32 key = keccak256(abi.encodePacked(msg.sender, flightName, timestamp));
        require(flights[key].isRegistered == true, "Requested Flight is not Found");
        return (
                    flights[key].isRegistered,
                    flights[key].statusCode,
                    flights[key].flightName,
                    flights[key].updatedTimestamp,
                    flights[key].airline
                );
    }

    /**
    * @dev Called for buying Flight Insurance
    *
    */ 

    function buyFlightInsurance(string calldata flightName, uint256 timestamp) external payable
    {
        bytes32 key = keccak256(abi.encodePacked(msg.sender, flightName, timestamp));
        require(flights[key].isRegistered == true, "Flight not found in the list");
        require(msg.value >= INSURANCE_FEE, "Minimum Insurance Fee of 1 Ether is Required");
        flightSuretyData.buyFlightInsurance.value(msg.value)(msg.sender,key , msg.value, flights[key].airline);
    }

    function getFlightInsurance(string calldata flightName, uint256 timestamp) external returns (bool, address, uint256) 
    {
        bool isRegistered;
        address buyerAddress;
        uint256 value;
        bytes32 key = keccak256(abi.encodePacked(msg.sender, flightName, timestamp));
        (isRegistered, buyerAddress, value) = flightSuretyData.getFlightInsurance(key);
        return (isRegistered, buyerAddress, value);
    }

   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                public
                                payable
    {
        if(statusCode == STATUS_CODE_LATE_TECHNICAL || statusCode == STATUS_CODE_LATE_AIRLINE ||
            statusCode == STATUS_CODE_LATE_OTHER || statusCode == STATUS_CODE_LATE_WEATHER)
        {
            bytes32 key = keccak256(abi.encodePacked(airline, flight, timestamp));
            require(flights[key].isRegistered == true, "Flight not found in the list");
            flightSuretyData.pay(airline, flight, timestamp, flights[key].airline);
        }
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            string calldata flight,
                            uint256 timestamp                            
                        )
                        external
    {
        bool isRegistered;
        address buyerAddress;
        uint256 value;
        bytes32 insuranceKey = keccak256(abi.encodePacked(msg.sender, flight, timestamp));
        (isRegistered, buyerAddress, value) = flightSuretyData.getFlightInsurance(insuranceKey);
        require(isRegistered == true, "User does not have Insurance");
        
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, msg.sender, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, msg.sender, flight, timestamp);
    } 


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;
    uint256 public constant INSURANCE_FEE = 1 ether;
    uint256 public constant INSURANCE_PAYOUT_FEE = 1.5 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string calldata flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}   

contract FlightSuretyData{
    function registerAirline(address airline, string calldata airlineName) external;
    function getAirline(address eoa) external returns(bool, string memory, uint256);
    function fund(address eoa) public payable;
    function buyFlightInsurance(address eoa, bytes32 key, uint256 value, address airline) public payable;
    function getFlightInsurance(bytes32 key) external returns (bool, address, uint256);
    function pay(address userAddress, string calldata flight, uint256 timestamp, address airline) external payable;
}