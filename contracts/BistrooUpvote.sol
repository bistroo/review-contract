pragma experimental ABIEncoderV2; // supports structs and arbitrarily nested arrays
pragma solidity>0.4.99<0.6.0;

/// @author Robert Rongen, Blockchain Advies
/// @title Reward contract for Bistroo

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";   // to send and receive ERC777 tokens
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";   // to receive ERC777 tokens
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";   // to send ERC777 tokens
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/introspection/ERC1820Implementer.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @dev BistrooUpvote registers upvotes and rewards Bistroo tokens after upvote goal is reached.
/// @dev Admin sets upvote parameters.
contract BistrooUpvote is Ownable, IERC777Recipient, IERC777Sender, ERC1820Implementer {

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    bytes32 constant public TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    IERC777 public bistrooToken;
    using SafeMath for uint256;

    /// @param paused: Pauses the smart contract if set to true
    /// @param admin: sets upvote parameters
    /// @param registrar: registers upvotes
	/// @param upvoteGoalConsumer: Number of upvotes a consumer must reach to get a reward
	/// @param upvoteGoalMerchant: Number of upvotes a merchant must reach to get a reward
	/// @param rewardConsumer: Reward a consumer gets when the upvoteGoalConsumer is reached
	/// @param rewardMerchant: Reward a merchant gets when the upvoteGoalMerchant is reached
	/// @param upvoteCode: Unique upvote identifier
	/// @param consumer: Upvotes an order, gets rewards for submitted upvotes
	/// @param merchant: Receives upvotes for an order, gets rewards for received upvotes 
    bool public paused = false;
    address admin;
    address registrar;
    uint256 upvoteGoalConsumer = 5;
    uint256 upvoteGoalMerchant = 10;
    uint256 rewardConsumer = 1;
    uint256 rewardMerchant = 1;

    mapping (address => uint256) public _upvotesConsumer;
    mapping (address => uint256) public _upvotesMerchant;

    event receivedTokens(address operator, address from, address to, uint256 amount, bytes userData, bytes operatorData);
    event sendTokens(address operator, address from, address to, uint256 amount, bytes userData, bytes operatorData);
    event pausedSet(bool paused);

    event adminChanged(address _admin);
    event registrarChanged(address _registrar);
    event parametersChanged(string _parameter, uint256 _value);
    event upvoteStatus(address _sender, address _merchant, string _message);
    
    /// @dev Link contract to Bistroo token.
    /// @dev For a smart contract to receive ERC777 tokens, it needs to implement the tokensReceived hook and register with ERC1820 registry as an ERC777TokensRecipient
    constructor (IERC777 tokenAddress, address setAdmin, address setRegistrar) public Ownable() {
        bistrooToken = IERC777(tokenAddress);
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        admin = setAdmin;
        registrar = setRegistrar;
    }

    /// @dev Function required by IERC777Recipient
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,   // asume only uint
        bytes calldata operatorData
    ) external {
        emit receivedTokens(operator, from, to, amount, userData, operatorData);
    }
    /// @dev Functions required by IERC777Sender
    function senderFor(address account) public {
        _registerInterfaceForAddress(TOKENS_SENDER_INTERFACE_HASH, account);
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) public {
        emit sendTokens(operator, from, to, amount, userData, operatorData);
    }

    /// @dev Custom functions
    /// @dev refer to https://ethereum.stackexchange.com/questions/729/how-to-concatenate-strings-in-solidity
    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    function upvotesOfConsumer(address account) public view returns (uint256) {
        return _upvotesConsumer[account];
    }

    function upvotesOfMerchant(address account) public view returns (uint256) {
        return _upvotesMerchant[account];
    }

    function setPaused(bool _paused) onlyOwner public {
        paused = _paused;
        emit pausedSet(paused);
    }
   
    function changeAdmin(address _admin) onlyOwner public {
        require(paused == false, "Contract is paused!");
        require(_admin != address(0), "Admin: account is the zero address");
        admin = _admin;
        emit adminChanged(_admin);
    }

    function changeRegistrar(address _registrar) onlyOwner public {
        require(paused == false, "Contract is paused!");
        require(_registrar != address(0), "Registrar: account is the zero address");
        registrar = _registrar;
        emit registrarChanged(_registrar);
    }

    function changeUpvoteGoalConsumer(uint256 _upvoteGoalConsumer) public {
        require(paused == false, "Contract is paused!");
        require(msg.sender == admin, "Only admin can change upvoteGoalConsumer");
        if (_upvoteGoalConsumer >= 1) {
            upvoteGoalConsumer = _upvoteGoalConsumer;
        } else return;
        emit parametersChanged("upvoteGoalConsumer", _upvoteGoalConsumer);
    }

    function changeUpvoteGoalMerchant(uint256 _upvoteGoalMerchant ) public {
        require(paused == false, "Contract is paused!");
        require(msg.sender == admin, "Only admin can change _upvoteGoalMerchant");
        if (_upvoteGoalMerchant >= 1) {
            upvoteGoalMerchant = _upvoteGoalMerchant;
        } else return;
        emit parametersChanged("upvoteGoalMerchant", _upvoteGoalMerchant);
    }

    function changeRewardConsumer(uint256 _rewardConsumer) public {
        require(paused == false, "Contract is paused!");
        require(msg.sender == admin, "Only admin can change rewardConsumer");
        if (_rewardConsumer >= 1) {
            rewardConsumer = _rewardConsumer;
        } else return;
        emit parametersChanged("rewardConsumer", _rewardConsumer);
    }

    function changeRewardMerchant(uint256 _rewardMerchant) public {
        require(paused == false, "Contract is paused!");
        require(msg.sender == admin, "Only admin can change rewardMerchant");
        if (_rewardMerchant >= 1) {
            rewardMerchant = _rewardMerchant;
        } else return;
        emit parametersChanged("rewardMerchant", _rewardMerchant);
    }

    /// @notice Register upvoteID parameters and store in struct
    function registerUpvote(address _consumer, address _merchant) public {
        // check Upvote not registered already
        require(msg.sender == registrar, "registerUpvote not triggered by registrar!");
        string memory _a = "upvotes registered";
        string memory _b = "";
        string memory _c = "";
        require(paused == false, "Contract is paused!");
        /// @dev set Upvote parameters
        if (_upvotesConsumer[_consumer] > 0) {
            _upvotesConsumer[_consumer]++;
            if (_upvotesConsumer[_consumer] >= upvoteGoalConsumer) {
                bistrooToken.send(_consumer, rewardConsumer, "0x");
                _upvotesConsumer[_consumer] = 0;
                _b = ", payout to consumer";
            }
        }
        if (_upvotesMerchant[_merchant] > 0) {
            _upvotesMerchant[_merchant]++;
            if (_upvotesMerchant[_merchant] >= upvoteGoalMerchant) {
                bistrooToken.send(_merchant, rewardMerchant, "0x");
                _upvotesMerchant[_merchant] = 0;
                _c = ", payout to merchant";
            }
        }
        string memory _message = append(_a, _b, _c); 
        // if 
        /// @dev push the new upvote to the array of upvotes
        emit upvoteStatus(_consumer, _merchant, _message);
    }
}