pragma solidity >=0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => uint256) authorizedContracts;

    struct Airline
    {
        bool isRegistered;
        string airlineName;
        uint balance;
    }

    struct Insurance
    {
        bool isRegistered;
        address buyerAddress;
        uint256 value;
        address airlineAddress;
        bool paymentDone;
    }

    //Mapping for Tracking Registered Airlines
    mapping(address => Airline) private airlines;

    //Mapping for Tracking Registered Insured 
    mapping(bytes32 => Insurance) private insurances;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        authorizedContracts[msg.sender] = 1;
    }

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
        require(operational, "Contract is currently not operational");
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

    modifier isCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == 1, "Caller is not authorized");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    function authorizeContracts(address appContract) external requireContractOwner
    {
        authorizedContracts[appContract] = 1;
    }

    function deauthorizeContracts(address appContract) external requireContractOwner
    {
        delete authorizedContracts[appContract];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                address airline,
                                string calldata airlineName
                            )
                            external
                            isCallerAuthorized
    {
        airlines[airline] = Airline({
            isRegistered: true,
            airlineName: airlineName,
            balance: 0
        });
    }

    function getAirline(address eoa) view external returns (bool, string memory, uint256)
    {
        require(airlines[eoa].isRegistered == true, "Airline is not found in the records");
        return(airlines[eoa].isRegistered, airlines[eoa].airlineName, airlines[eoa].balance);
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buyFlightInsurance
                            (
                                address eoa,
                                bytes32 key,
                                uint256 value,
                                address airlineAddress                           
                            )
                            external
                            payable
    {
        insurances[key] = Insurance(
        {
            isRegistered: true,
            buyerAddress: eoa,
            value: value,
            airlineAddress: airlineAddress,
            paymentDone: false
        });
    }

    function getFlightInsurance(bytes32 key) view external returns (bool, address, uint256)
    {
        require(insurances[key].isRegistered == true, "Insurance for this flight is not found");
        return (insurances[key].isRegistered, insurances[key].buyerAddress, insurances[key].value);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address payable userAddress, string calldata flight, uint256 timestamp, address airlineAddress
                            )
                            external
                            payable
    {
        bytes32 key = keccak256(abi.encodePacked(userAddress, flight, timestamp));
        require(insurances[key].isRegistered == true, "Insurance not found in the records");
        require(insurances[key].paymentDone == false, "Insuree has already been paid");
        require(airlines[airlineAddress].isRegistered == true, "Airline not found in the records");
        require(airlines[airlineAddress].balance >= 2 ether, "Airline balance is low");
        
        insurances[key].paymentDone = true;
        airlines[airlineAddress].balance = airlines[airlineAddress].balance - 1.5 ether;
        userAddress.transfer(1.5 ether);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                                address eoa
                            )
                            public
                            payable
    {
        require(airlines[eoa].isRegistered == true, "Airline address not found in the records. Register the airline first");
        airlines[eoa].balance = airlines[eoa].balance + msg.value;
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

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable
                            
    {
        fund(msg.sender);
    }


}

