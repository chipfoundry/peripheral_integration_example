# SPDX-FileCopyrightText: 2023 Efabless Corporation

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
from caravel_cocotb.caravel_interfaces import UART
from caravel_cocotb.caravel_interfaces import SPI
import cocotb
import random

@cocotb.test()
@report_test
async def spi_uart_basic(dut):
    """Test basic SPI and UART functionality through GPIO control"""
    caravelEnv = await test_configure(dut, timeout_cycles=100000)

    cocotb.log.info(f"[TEST] Start spi_uart_basic test")
    
    # Wait for configuration to complete
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    cocotb.log.info(f"[TEST] Configuration finished")
    
    # Wait for test setup to complete
    await caravelEnv.wait_mgmt_gpio(0)
    cocotb.log.info(f"[TEST] Test setup finished")
    
    # Test 1: Check that SPI and UART are enabled via GPIO 13 and 14
    spi_en = caravelEnv.monitor_gpio(13, 13).integer
    uart_en = caravelEnv.monitor_gpio(14, 14).integer
    
    if spi_en != 1:
        cocotb.log.error(f"SPI enable should be 1, got {spi_en}")
    if uart_en != 1:
        cocotb.log.error(f"UART enable should be 1, got {uart_en}")
    
    # Test 2: Check initial GPIO states
    # SPI pins should be in idle state when enabled
    spi_mosi = caravelEnv.monitor_gpio(5, 5).integer
    spi_sclk = caravelEnv.monitor_gpio(7, 7).integer
    spi_csb = caravelEnv.monitor_gpio(8, 8).integer
    uart_tx = caravelEnv.monitor_gpio(9, 9).integer
    
    # SPI should be idle (CSB high, SCLK low, MOSI low)
    if spi_csb != 1:
        cocotb.log.error(f"SPI CSB should be high (idle), got {spi_csb}")
    if spi_sclk != 0:
        cocotb.log.error(f"SPI SCLK should be low (idle), got {spi_sclk}")
    if spi_mosi != 0:
        cocotb.log.error(f"SPI MOSI should be low (idle), got {spi_mosi}")
    
    # UART TX should be high (idle)
    if uart_tx != 1:
        cocotb.log.error(f"UART TX should be high (idle), got {uart_tx}")
    
    cocotb.log.info(f"[TEST] Basic GPIO state verification passed")

@cocotb.test()
@report_test
async def spi_uart_wishbone(dut):
    """Test Wishbone bus access to SPI and UART registers"""
    caravelEnv = await test_configure(dut, timeout_cycles=100000)

    cocotb.log.info(f"[TEST] Start spi_uart_wishbone test")
    
    # Wait for configuration to complete
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    await caravelEnv.wait_mgmt_gpio(0)
    
    # Test Wishbone access to control registers (0xF000-0xFFFF)
    # Read version register (0xF008)
    version = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
    cocotb.log.info(f"[TEST] Version register read: {version}")
    
    # Read status register (0xF000)
    status = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
    cocotb.log.info(f"[TEST] Status register read: {status}")
    
    # Test SPI register access (0x0000-0x0FFF)
    # Read SPI configuration register (0x0008)
    spi_cfg = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
    cocotb.log.info(f"[TEST] SPI config register read: {spi_cfg}")
    
    # Test UART register access (0x1000-0x1FFF)
    # Read UART configuration register (0x1010)
    uart_cfg = caravelEnv.caravel_hdl.mprj.wbs_dat_o.value.integer
    cocotb.log.info(f"[TEST] UART config register read: {uart_cfg}")
    
    cocotb.log.info(f"[TEST] Wishbone register access test completed")

@cocotb.test()
@report_test
async def spi_uart_interrupts(dut):
    """Test interrupt functionality for SPI and UART"""
    caravelEnv = await test_configure(dut, timeout_cycles=100000)

    cocotb.log.info(f"[TEST] Start spi_uart_interrupts test")
    
    # Wait for configuration to complete
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    await caravelEnv.wait_mgmt_gpio(0)
    
    # Check initial interrupt state
    spi_irq = caravelEnv.caravel_hdl.mprj.irq[0].value.integer
    uart_irq = caravelEnv.caravel_hdl.mprj.irq[1].value.integer
    
    cocotb.log.info(f"[TEST] Initial SPI IRQ: {spi_irq}, UART IRQ: {uart_irq}")
    
    # Monitor interrupts for a few cycles
    for i in range(1000):
        await cocotb.triggers.ClockCycles(caravelEnv.clk, 1)
        spi_irq = caravelEnv.caravel_hdl.mprj.irq[0].value.integer
        uart_irq = caravelEnv.caravel_hdl.mprj.irq[1].value.integer
        
        if spi_irq == 1:
            cocotb.log.info(f"[TEST] SPI interrupt detected at cycle {i}")
        if uart_irq == 1:
            cocotb.log.info(f"[TEST] UART interrupt detected at cycle {i}")
    
    cocotb.log.info(f"[TEST] Interrupt monitoring completed")

@cocotb.test()
@report_test
async def spi_uart_gpio_control(dut):
    """Test GPIO control of SPI and UART enable signals"""
    caravelEnv = await test_configure(dut, timeout_cycles=100000)

    cocotb.log.info(f"[TEST] Start spi_uart_gpio_control test")
    
    # Wait for configuration to complete
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    await caravelEnv.wait_mgmt_gpio(0)
    
    # Test 1: Disable SPI (GPIO 13 = 0)
    caravelEnv.drive_gpio_in(13, 0)
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 100)
    
    # Check that SPI pins are disabled
    spi_mosi = caravelEnv.monitor_gpio(5, 5).integer
    spi_sclk = caravelEnv.monitor_gpio(7, 7).integer
    spi_csb = caravelEnv.monitor_gpio(8, 8).integer
    
    if spi_mosi != 0:
        cocotb.log.error(f"SPI MOSI should be 0 when disabled, got {spi_mosi}")
    if spi_sclk != 0:
        cocotb.log.error(f"SPI SCLK should be 0 when disabled, got {spi_sclk}")
    if spi_csb != 1:
        cocotb.log.error(f"SPI CSB should be 1 when disabled, got {spi_csb}")
    
    # Test 2: Re-enable SPI (GPIO 13 = 1)
    caravelEnv.drive_gpio_in(13, 1)
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 100)
    
    # Test 3: Disable UART (GPIO 14 = 0)
    caravelEnv.drive_gpio_in(14, 0)
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 100)
    
    # Check that UART TX is disabled (should be high when disabled)
    uart_tx = caravelEnv.monitor_gpio(9, 9).integer
    if uart_tx != 1:
        cocotb.log.error(f"UART TX should be 1 when disabled, got {uart_tx}")
    
    # Test 4: Re-enable UART (GPIO 14 = 1)
    caravelEnv.drive_gpio_in(14, 1)
    await cocotb.triggers.ClockCycles(caravelEnv.clk, 100)
    
    cocotb.log.info(f"[TEST] GPIO control test completed")

@cocotb.test()
@report_test
async def spi_uart_logic_analyzer(dut):
    """Test logic analyzer integration for debugging"""
    caravelEnv = await test_configure(dut, timeout_cycles=100000)

    cocotb.log.info(f"[TEST] Start spi_uart_logic_analyzer test")
    
    # Wait for configuration to complete
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    await caravelEnv.wait_mgmt_gpio(0)
    
    # Monitor logic analyzer outputs
    for i in range(1000):
        await cocotb.triggers.ClockCycles(caravelEnv.clk, 1)
        
        # Read logic analyzer data
        la_data = caravelEnv.caravel_hdl.mprj.la_data_out.value.integer
        
        # Extract relevant bits for monitoring
        wb_data = (la_data >> 0) & 0xFFFFFFFF
        wb_addr = (la_data >> 32) & 0xFFFF
        gpio_status = (la_data >> 48) & 0xFFFF
        irq_status = (la_data >> 64) & 0xFFFFFFFF
        
        # Log interesting events
        if i % 100 == 0:
            cocotb.log.info(f"[TEST] Cycle {i}: WB_DATA={wb_data:08x}, WB_ADDR={wb_addr:04x}, GPIO={gpio_status:04x}, IRQ={irq_status:08x}")
    
    cocotb.log.info(f"[TEST] Logic analyzer monitoring completed") 