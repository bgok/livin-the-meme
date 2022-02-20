// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {
    struct TokenData {
        bool physicalObjectClaimed;
        bool physicalObjectDelivered;
        string name;
        bool nameChangeAvailable;
    }
    bool public publicMintingStarted = false;
    mapping(uint256 => TokenData) private tokenData;

    event PhysicalBadgeRequested(uint256 tokenId, bytes[32] requestHash);
    event PhysicalBadgeDelivered(uint256 tokenId);

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("LivinTheMeme", "LTM", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://creatures-api.op    ensea.io/api/creature/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://creatures-api.opensea.io/contract/opensea-creatures";
    }

    function mintTo(address _to, string memory _name) public onlyOwner override {
        uint256 currentTokenId = getNextTokenId();
        super.mintTo(_to);
        tokenData[currentTokenId] = TokenData({
            physicalObjectClaimed: false,
            physicalObjectDelivered: false,
            name: _name,
            nameChangeAvailable: false
        });
    }

    function changeName(uint256 id, string newName) public {
        require(tokenData[id].nameChangeAvailable, "Name change is not available for that token");
        require(ownerOf(id) == _msgSender(), "Only the token owner can change the name");
        tokenData[id].name = newName;
        tokenData[id].nameChangeAvailable = false;
    }

    function setPublicMinting(_publicMintingAllowed) public onlyOwner {
        publicMintingStarted = _publicMintingAllowed;
    }

    function registerBadge(address _to, string memory name) public virtual {
        // TODO: require that the name is signed by the contract owner
        require(publicMintingStarted, "badge registration not started");

    }

    function registerPhysicalBadgeRequest(uint256 tokenId, bytes[32] requestHash) public virtual {
        require(ownerOf(id) == _msgSender(), "Only the token owner can claim");
        require(!tokenData[tokenId].physicalObjectClaimed, "Already claimed");
        tokenData[tokenId].physicalObjectClaimed = true;
        emit PhysicalBadgeRequested(tokenId, requestHash);
    }

    function sendPhysicalBadge(uint256 tokenId) public virtual onlyOwner {
        tokenData[tokenId].physicalObjectClaimed = true;
        tokenData[tokenId].physicalObjectDelivered = true;
        emit PhysicalBadgeDelivered(tokenId);
    }
}
