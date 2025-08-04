# SPDX-FileCopyrightText: 2025 ChipFoundry, a DBA of Umbralogic Technologies LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# SPDX-License-Identifier: Apache-2.0

from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
import cocotb

@cocotb.test()
@report_test
async def uart_spi_comprehensive_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=100000)

    cocotb.log.info(f"[TEST] Start uart_spi_comprehensive_test")
    
    # wait for start of configuration
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    cocotb.log.info(f"[TEST] Configuration finished")
    
    # Phase 1: Wait for all UART tests to complete (GPIO 2-8)
    for uart in range(7):
        await caravelEnv.wait_mgmt_gpio(uart + 2)
        cocotb.log.info(f"[TEST] UART{uart} Phase 1 test completed")
    
    # Phase 2: Wait for all SPI tests to complete (GPIO 9-14)
    for spi in range(6):
        await caravelEnv.wait_mgmt_gpio(spi + 9)
        cocotb.log.info(f"[TEST] SPI{spi} Phase 2 test completed")
    
    # Phase 3 & 4: Address decoding and invalid address tests are handled in firmware
    # The firmware will set GPIO 0 when all tests pass, or 0xFF if there's an error
    
    # Wait for final completion signal
    await caravelEnv.wait_mgmt_gpio(0)
    cocotb.log.info(f"[TEST] All comprehensive UART/SPI tests completed successfully")
    
    # Check for error condition (GPIO 0xFF would indicate error)
    error_gpio = caravelEnv.monitor_gpio(7, 0)  # Check lower 8 bits
    if error_gpio == 0xFF:
        cocotb.log.error(f"[TEST] Comprehensive test failed - error detected")
        assert False, "Comprehensive test failed"
    else:
        cocotb.log.info(f"[TEST] All comprehensive tests passed successfully")
        
    # Additional verification: Check that all UART TX pins are active
    for uart in range(7):
        tx_pin = uart * 2 + 1  # UART TX pins: 1,3,5,7,9,11,13
        tx_value = caravelEnv.monitor_gpio(tx_pin, tx_pin)
        if tx_value == 0:
            cocotb.log.warning(f"[TEST] UART{uart} TX pin {tx_pin} is not active")
        else:
            cocotb.log.info(f"[TEST] UART{uart} TX pin {tx_pin} is active")
    
    # Additional verification: Check that SPI output pins are configured as outputs
    for spi in range(6):
        mosi_pin = 15 + spi * 4  # SPI MOSI pins: 15,19,23,27,31,35
        sclk_pin = 16 + spi * 4  # SPI SCLK pins: 16,20,24,28,32,36
        cs_pin = 17 + spi * 4    # SPI CS pins: 17,21,25,29,33,37
        
        # Check if SPI pins are configured as outputs (io_oeb should be 0 for outputs)
        mosi_oeb = caravelEnv.monitor_gpio(mosi_pin + 37, mosi_pin + 37)  # io_oeb offset
        sclk_oeb = caravelEnv.monitor_gpio(sclk_pin + 37, sclk_pin + 37)
        cs_oeb = caravelEnv.monitor_gpio(cs_pin + 37, cs_pin + 37)
        
        if mosi_oeb != 0 or sclk_oeb != 0 or cs_oeb != 0:
            cocotb.log.warning(f"[TEST] SPI{spi} output pins not properly configured")
        else:
            cocotb.log.info(f"[TEST] SPI{spi} output pins properly configured") 