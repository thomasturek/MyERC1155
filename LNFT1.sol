// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./utils/ContextMixin.sol";
import "./utils/IChildToken.sol";

contract LNFT1 is ERC1155, AccessControl, ERC1155Burnable, IChildToken, ContextMixin {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
 
    mapping(uint256 => string) private _tokenUris;

    // 0x0000000000000000000000000000000000000000
    //ETH
    // Mainnet MINTER_ROLE 0x2d641867411650cd05dB93B59964536b1ED5b1B7
    // Goerli  MINTER_ROLE 0x72d6066F486bd0052eefB9114B66ae40e0A6031a

    // Polygon
    // Mumbai DEPOSITOR_ROLE 0xb5505a6d998549090530911180f38aC5130101c6
    //constructor(address polygonChainManager, address mainMinter) 
    //    ERC1155("Uri is per Id -> use methode uri(id)") 
    //{
        //_grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        //_grantRole(URI_SETTER_ROLE, _msgSender());
        //_grantRole(MINTER_ROLE, _msgSender());

        //if (mainMinter != address(0)){
        //    _grantRole(MINTER_ROLE, mainMinter);
        //}
        //if (polygonChainManager != address(0)){
        //    _grantRole(DEPOSITOR_ROLE, polygonChainManager);
        //}
    //}

    constructor() 
        ERC1155("Uri is per Id -> use methode uri(id)") 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }


    function uri(uint256 id) public view virtual override returns (string memory) {
        return _tokenUris[id];
    }
   
    function _setURI(uint256 id, string memory newuri) internal virtual {
        _tokenUris[id] = newuri;
    }

    function _setURIBatch(uint256[] memory ids, string[] memory newuris) internal virtual {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            _tokenUris[id] = newuris[i];            
        }
    }

    function mint(address account, uint256 id, uint256 amount, string memory newuri)
        public
        onlyRole(MINTER_ROLE)
    {
        require(keccak256(abi.encodePacked(_tokenUris[id])) == keccak256(abi.encodePacked("")),
            "Token id was already used");

        _mint(account, id, amount, new bytes(0));
        _setURI(id, newuri);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, string[] memory newuris)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, new bytes(0));
        _setURIBatch(ids, newuris);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        view
        override
        returns (address)
    {
        return ContextMixin.msgSender();
    }


    /**
     * @notice called when tokens are deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required tokens for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded ids array and amounts array
     */
    function deposit(address user, bytes calldata depositData)
        external
        override
        onlyRole(DEPOSITOR_ROLE)
    {
        (
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data
        ) = abi.decode(depositData, (uint256[], uint256[], bytes));

        require(
            user != address(0),
            "ChildMintableERC1155: INVALID_DEPOSIT_USER"
        );

        _mintBatch(user, ids, amounts, data);
    }

    /**
     * @notice called when user wants to withdraw single token back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param id id to withdraw
     * @param amount amount to withdraw
     */
    function withdrawSingle(uint256 id, uint256 amount) external {
        _burn(_msgSender(), id, amount);
    }

    /**
     * @notice called when user wants to batch withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param ids ids to withdraw
     * @param amounts amounts to withdraw
     */
    function withdrawBatch(uint256[] calldata ids, uint256[] calldata amounts)
        external
    {
        _burnBatch(_msgSender(), ids, amounts);
    }

}
