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
async def uart_spi_reg_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=50000)

    cocotb.log.info(f"[TEST] Start uart_spi_reg_test")
    
    # wait for start of configuration
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    cocotb.log.info(f"[TEST] Configuration finished")
    
    # Wait for all UART register tests to complete (GPIO 2-8)
    for uart in range(7):
        await caravelEnv.wait_mgmt_gpio(uart + 2)
        cocotb.log.info(f"[TEST] UART{uart} register test completed")
    
    # Wait for all SPI register tests to complete (GPIO 9-14)
    for spi in range(6):
        await caravelEnv.wait_mgmt_gpio(spi + 9)
        cocotb.log.info(f"[TEST] SPI{spi} register test completed")
    
    # Wait for final completion signal
    await caravelEnv.wait_mgmt_gpio(0)
    cocotb.log.info(f"[TEST] All UART/SPI register tests completed successfully")
    
    # Check for error condition (GPIO 0xFF would indicate error)
    error_gpio = caravelEnv.monitor_gpio(7, 0)  # Check lower 8 bits
    if error_gpio == 0xFF:
        cocotb.log.error(f"[TEST] Register test failed - error detected")
        assert False, "Register test failed"
    else:
        cocotb.log.info(f"[TEST] All register tests passed successfully") 