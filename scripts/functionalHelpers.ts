import { ethers } from "hardhat";
import { BigNumber } from 'ethers'

export const toWei = (x: number) => ethers.utils.parseUnits(x.toString(), 'ether')
export const fromWei = (x: BigNumber) => ethers.utils.formatEther(x)

export const randomAddress = () => `0x${[...Array(40)]
    .map(() => Math.floor(Math.random() * 16).toString(16))
    .join('')}`;

export const getRandomAccount = async () => 
    await ethers.getImpersonatedSigner(randomAddress())

export const getRandomFundedAccount = async (funds: number = 10) => {
    const acc = await getRandomAccount() 
    const [admin, ] = await ethers.getSigners()
    await admin.sendTransaction({to: acc.address, value: toWei(funds)})
    return acc
};

