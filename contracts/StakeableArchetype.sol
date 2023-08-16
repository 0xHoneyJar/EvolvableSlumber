// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISharesHolder.sol";
import "./interfaces/IEvolutionStrategy.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SafeTransferLib.sol";


//struct StakeTokenInfo {
//    // `stakedTime == 0` iff the token has not been manually staked.
//    uint32 stakedTimestamp;
//    uint32 totalTimeStaked;
//}

struct StakingConfig {
    uint32 minStakingTime;
    uint32 automaticStakeTimeOnMint;
    uint32 automaticStakeTimeOnTx;
}

struct Config {
    uint128 deployTime;
    uint128 price;
    string baseUri;
    StakingConfig stakingConfig;
}

/**
 * @title StakeableArchetype
 *
 * @dev This contract implements a novel staking mechanism:
 * 
 * - Tokens can get automatically staked on mint for a certain amount of time.
 * - Tokens can get automatically staked on tx for a certain amount of time.
 * - If not, tokens can get manually staked by the user.
 *
 * In any of those cases, the user will be able to extend staking time, if not,
 * the token will get automatically unstaked to minimize contract interaction.
 */
contract StakeableArchetype is ERC721A, Ownable {

    // TODO Overwrite 721A words.
    // mapping (uint256 => StakeTokenInfo) private _tokenIdToStakeInfo;
    Config private _config;

    constructor(
        string memory name,
        string memory ticker,
        Config memory config
    ) ERC721A(name, ticker) {
        _config = config;
    }

    function mint(uint16 quantity) external payable {
        require(msg.value >= _config.price * quantity);

        uint256 fstNextId = _nextTokenId();
        _mint(msg.sender, quantity);

        // If tokens should get staked automatically on mint,
        // set a flag so the contract knows it happened.
        if (_config.stakingConfig.automaticStakeTimeOnMint > 0)
            _setExtraDataAt(fstNextId, 1);
    }

    function stake(uint256 tokenId, uint32 time) public {
        require(time >= _config.stakingConfig.minStakingTime);
        require(ownerOf(tokenId) == msg.sender);
        require(!isStaked(tokenId));

        _tokenIdToStakeInfo[tokenId].stakedTimestamp = uint32(block.timestamp);
    }

    function isStaked(uint256 tokenId) public view returns (bool) {
        return _tokenIdToStakeInfo[tokenId].stakedTimestamp != 0
            || getTokenIsStakedOnMint(tokenId);
    }

    function canGetUnstaked(uint256 tokenId) public view returns (bool) {
        return isStaked(tokenId) && (
            _tokenIdToStakeInfo[tokenId].stakedTimestamp + _config.stakingConfig.minStakingTime
        ) < block.timestamp;
    }

    /**
     * @return If `tokenId` is currently staked because the automatic stake on mints.
     */
    function getTokenIsStakedOnMint(uint256 tokenId) public view returns (bool) {
        if (getTokenGotStakedOnMint(tokenId)) {
            uint256 onMintStakingTime = _config.stakingConfig.automaticStakeTimeOnMint;
            uint256 unstakeTime = getMintTime(tokenId) + onMintStakingTime;
            return block.timestamp < unstakeTime;
        }
        return false;
    }

    function getTokenGotStakedOnMint(uint256 tokenId) public view returns (bool) {
        return _ownershipOf(tokenId).extraData == 1;
    }

    function getMintTime(uint256 tokenId) public view returns (uint256) {
        return _ownershipOf(tokenId).startTimestamp;
    }


    function tokenURI(uint256 tokenId) 
        public 
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));
        if (bytes(_config.baseUri).length == 0) return "";

        return string(abi.encodePacked(
            _config.baseUri,
            LibString.toString(tokenId)
        ));
    }

    function withdraw() public onlyOwner {
        SafeTransferLib.forceSafeTransferETH(msg.sender, address(this).balance);
    }

    // FIXME Suboptimal, work on a ERC721A integration.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        for (startTokenId; startTokenId <= quantity; startTokenId++)
            require(!isStaked(startTokenId)); 
    }
}

