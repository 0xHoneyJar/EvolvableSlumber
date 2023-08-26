import { ethers } from 'hardhat'
import { DeploymentConfigStruct } from '../typechain-types/contracts/ERC721S'
import { toWei } from './functionalHelpers'

export const deployMinimalErc721S = async ({
    name = 'TestToken',
    symbol = 'TEST',
    price = toWei(0.1),
    minStakingTime = (60 * 60 * 24), // 1 Day.
    automaticStakeTimeOnMint = (60 * 60 * 24), // 1 Day.
    automaticStakeTimeOnTx = (60 * 60 * 12), // 12 Hours.
    baseUri = 'https://exampleUri.com/'
}) => {
    const erc721sFactory = await ethers.getContractFactory('MinimalErc721SImpl')

    const deploymentConfig: DeploymentConfigStruct = {
        price,
        minStakingTime,
        automaticStakeTimeOnMint,
        automaticStakeTimeOnTx,
        baseUri
    }

    return await erc721sFactory.deploy(
        name,
        symbol,
        deploymentConfig
    )
}
