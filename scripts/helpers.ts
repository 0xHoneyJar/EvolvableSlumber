import { ethers } from 'hardhat'
import { DeploymentConfigStruct } from '../typechain-types/contracts/ERC721S'
import { MinimalErc721SImpl } from '../typechain-types'
import * as RNEA from 'fp-ts/ReadonlyNonEmptyArray'
import { getRandomAccount, randExpRange } from './functionalHelpers'

/**
 *  Randomly mints a token following an exponential distribution, returns
 *  the expected ownerships.
 *  
 *  Side effects:
 *  - Will interact and change the state of the passed contract.
 */
export const randomAirdrop = async (
    nft: MinimalErc721SImpl, maxSupply: number, stake = false
) => {

    var i = 1
    var ownersAndOwnedIds = []

    while (i <= maxSupply) {
        const holder = await getRandomAccount()
        const holderOwns = randExpRange(1, [1, maxSupply - i + 1])
        const fstId = await nft.totalSupply().then(n => n.toNumber())

        ownersAndOwnedIds.push({
            owner: holder,
            ownedIds: [...RNEA.range(fstId, fstId + holderOwns)]
        })

        for (var j = 1; j <= holderOwns; j++) {
            if (stake) await nft.mintAndStake(holder.address, holderOwns)
            else await nft.mint(holder.address, holderOwns)
            i++
        }
    }

    return ownersAndOwnedIds
}


export const deployMinimalErc721S = async ({
    name = 'TestToken',
    symbol = 'TEST',
    minStakingTime = (60 * 60 * 24), // 1 Day.
    automaticStakeTimeOnMint = (60 * 60 * 24), // 1 Day.
    automaticStakeTimeOnTx = (60 * 60 * 12), // 12 Hours.
}) => {
    const erc721sFactory = await ethers.getContractFactory('MinimalErc721SImpl')

    const deploymentConfig: DeploymentConfigStruct = {
        name,
        symbol,
        minStakingTime,
        automaticStakeTimeOnMint,
        automaticStakeTimeOnTx,
    }

    return await erc721sFactory.deploy(deploymentConfig)
}
