pragma solidity ^0.5.0;

import "./ERC1155.sol";
import "./Owned.sol";

/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items.
*/
contract ERC1155Mintable is ERC1155, Owned {

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    // id => creators
    mapping (uint256 => address payable) public creators;
    
    mapping (address => uint256[]) public ownedContents;
    
    // id => DynamoDB URI
    mapping (uint256 => string) public dataUri;
    
    // id => price
    mapping (uint256 => uint256) public prices;

    // id => virality
    mapping (uint256 => uint256) public virality;

    // contentUuid => id
    mapping (string => uint256) private ids;

    // A nonce to ensure we have a unique id each time we mint.
    uint256 public nonce;

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }

    function supportsInterface(bytes4 _interfaceId)
    public
    view
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }
    
    function updatePrice(uint256 _id, uint256 _newPrice) public onlyOwner  {
        prices[_id] = _newPrice;
    }

    function batchUpdatePrice(uint256[] memory _ids, uint256[] memory _newPrices) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            prices[_ids[i]] = _newPrices[i];
        }
    }

    function updateVirality(uint256 _id, uint256 _newVirality) public onlyOwner {
        virality[_id] = _newVirality;
        prices[_id] = prices[_id] + (_newVirality / 100);
    }

    function batchUpdateVirality(uint256[] memory _ids, uint256[] memory _newViralities) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            virality[_ids[i]] = _newViralities[i];
        }
    }
    
    function buy(uint256 _id, uint256 _quantity) external payable returns (uint256) {
        address payable creator = creators[_id];
        // Validate Buyer is not creator
        require(creator != msg.sender, "Creator Cannot Buy his own creation");
        
        // VALIDATE PAYMENT FIRST
        uint256 totalPrice = prices[_id] * _quantity;
        require(msg.value >= totalPrice, "Insufficient Payment");
        
        // Pay the creator
        creator.transfer(msg.value);
        
        // Add to owned content
        ownedContents[msg.sender].push(_id);
        
        // Give tokens of content to buyer
        balances[_id][creator] = balances[_id][creator].sub(_quantity);
        // balances[_id][msg.sender] = balances[_id][msg.sender].add(_quantity);
        balances[_id][msg.sender] = _quantity.add(balances[_id][msg.sender]);
    }

    function getId(string memory _uuid) public view returns (uint256) {
        return ids[_uuid];
    }
    

    // Creates a new token type and assings _initialSupply to minter
    function create(uint256 _initialSupply, uint256 _price, string calldata _uri, string calldata uuid) external payable returns(uint256 _id) {
        
        // Validate creator stake payment
        uint256 totalPrice = _price.mul(_initialSupply);
        
        require(msg.value >= totalPrice, "Insufficient stake amount");

        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = _initialSupply;

        // Add UUID
        ids[uuid] = _id;
        
        // Add URI
        dataUri[_id] = _uri;
        
        // Add price
        prices[_id] = _price;

        // Add virality
        virality[_id] = 100;
        
        // Add to owned content
        // ownedContents[msg.sender].push(_id);

        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _initialSupply);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _id);
    }

    // Batch mint tokens. Assign directly to _to[].
    function mint(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external creatorOnly(_id) {

        for (uint256 i = 0; i < _to.length; ++i) {

            address to = _to[i];
            uint256 quantity = _quantities[i];

            // Grant the items to the caller
            balances[_id][to] = quantity.add(balances[_id][to]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, to, _id, quantity, '');
            }
        }
    }

    function setURI(string calldata _uri, uint256 _id) external creatorOnly(_id) {
        dataUri[_id] = _uri;
        emit URI(_uri, _id);
    }
}