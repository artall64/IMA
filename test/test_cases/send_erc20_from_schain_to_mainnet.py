from time import sleep, time
from logging import debug, error

from tools.test_case import TestCase
from tools.test_pool import test_pool
from tools.utils import set_ima_to_schain_nodes
from tools.utils import restart_skaled
import time


class SendERC20ToMainnet(TestCase):
    erc20 = None
    erc20_clone = None
    amount = 4
    # index of token in lock_and_data_for_schain_erc20.sol
    index = 1

    def __init__(self, config):
        super().__init__('Send ERC20 from schain to mainnet', config)

    def _prepare(self):
        set_ima_to_schain_nodes(self.config.schain_name, self.config.mainnet_rpc_url)
        time.sleep(2)
        restart_skaled(self.config.schain_name)
        time.sleep(2)
        # deploy token
        self.erc20 = self.blockchain.deploy_erc20_on_mainnet(self.config.mainnet_key, 'D2-Token', 'D2', 100)

        # mint

        address = self.blockchain.key_to_address(self.config.mainnet_key)
        mint_txn = self.erc20.functions.mint(address, self.amount)\
            .buildTransaction({
                'gas': 8000000,
                'nonce': self.blockchain.get_transactions_count_on_mainnet(address)})

        signed_txn = self.blockchain.web3_mainnet.eth.account.signTransaction(mint_txn,
                                                                              private_key=self.config.mainnet_key)
        self.blockchain.web3_mainnet.eth.sendRawTransaction(signed_txn.rawTransaction)

        # send to schain

        self.agent.transfer_erc20_from_mainnet_to_schain(self.erc20,
                                                         self.config.mainnet_key,
                                                         self.config.schain_key,
                                                         self.amount,
                                                         self.timeout)

        amount_of_eth = 90 * 10 ** 15

        self.agent.transfer_eth_from_mainnet_to_schain(self.config.mainnet_key,
                                                       self.config.schain_key,
                                                       amount_of_eth,
                                                       self.timeout)

        self.blockchain.add_eth_cost(self.config.schain_key,
                                     amount_of_eth)

        self.erc20_clone = self.blockchain.get_erc20_on_schain(self.index)

    def _execute(self):
        source_address = self.blockchain.key_to_address(self.config.schain_key)
        destination_address = self.blockchain.key_to_address(self.config.mainnet_key)

        if self.erc20_clone.functions.balanceOf(source_address).call() < self.amount:
            error("Not enough tokens to send")
            return
        balance = self.erc20.functions.balanceOf(destination_address).call()

        self.agent.transfer_erc20_from_schain_to_mainnet(self.erc20_clone, # token
                                                         self.config.schain_key, # from
                                                         self.config.mainnet_key, # to
                                                         (self.amount - 2), # 2 tokens
                                                         self.index,
                                                         self.timeout)

        # if self.erc20.functions.balanceOf(destination_address).call() == balance + self.amount:
        if self.erc20.functions.balanceOf(destination_address).call() == (self.amount - 2):
            self._mark_passed()


test_pool.register_test(SendERC20ToMainnet)
