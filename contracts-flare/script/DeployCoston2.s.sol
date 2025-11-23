// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SponsorDelegationVault.sol";

contract DeployCoston2Script is Script {
    // Direcciones reales en Coston2
    address constant WNAT_COSTON2 = 0xC67DCE33D7A8efA5FfEB961899C73fe01bCe9273;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Usamos el deployer como dataProvider inicial (puedes cambiarlo después)
        SponsorDelegationVault vault = new SponsorDelegationVault(WNAT_COSTON2, deployer);

        console.log("SponsorVault deployed at:", address(vault));

        vm.stopBroadcast();
    }
}
