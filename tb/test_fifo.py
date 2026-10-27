
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_fifo_basic(dut):
    # Initialize inputs
    dut.winc.value = 0
    dut.rinc.value = 0
    dut.wdata.value = 0
    dut.wrst_n.value = 0
    dut.rrst_n.value = 0

    # Start independent clocks
    cocotb.start_soon(Clock(dut.wclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.rclk, 14, unit="ns").start())

    # Hold reset for several clock cycles
    await Timer(50, unit="ns")

    assert int(dut.rempty.value) == 1, "FIFO should be empty after reset"
    assert int(dut.wfull.value) == 0, "FIFO should not be full after reset"

    # Release reset
    dut.wrst_n.value = 1
    dut.rrst_n.value = 1

    await Timer(50, unit="ns")

    # Write one byte, keeping inputs stable across one write edge
    await RisingEdge(dut.wclk)
    await Timer(1, unit="ns")
    dut.wdata.value = 0xA5
    dut.winc.value = 1

    await RisingEdge(dut.wclk)
    await Timer(1, unit="ns")
    dut.winc.value = 0

    # Wait for write pointer synchronization into read domain
    for _ in range(10):
        await RisingEdge(dut.rclk)
        await Timer(1, unit="ns")
        if int(dut.rempty.value) == 0:
            break
    else:
        assert False, "FIFO never became non-empty"

    # Asynchronous memory output should show oldest data
    assert int(dut.rdata.value) == 0xA5, "Incorrect FIFO data"

    # Read one byte
    dut.rinc.value = 1
    await RisingEdge(dut.rclk)
    await Timer(1, unit="ns")
    dut.rinc.value = 0

    # Check FIFO returns to empty
    assert int(dut.rempty.value) == 1, "FIFO should be empty after reading"

@cocotb.test()
async def test_fifo_ordering(dut):
    test_data = [0xA5, 0x3C, 0xF0, 0x12]

    # Initialize inputs
    dut.wclk.value = 0
    dut.rclk.value = 0
    dut.winc.value = 0
    dut.rinc.value = 0
    dut.wdata.value = 0
    dut.wrst_n.value = 0
    dut.rrst_n.value = 0

    # Independent write and read clocks
    cocotb.start_soon(Clock(dut.wclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.rclk, 14, unit="ns").start())

    # Reset both clock domains
    await Timer(50, unit="ns")

    assert int(dut.rempty.value) == 1
    assert int(dut.wfull.value) == 0

    dut.wrst_n.value = 1
    dut.rrst_n.value = 1

    await Timer(50, unit="ns")

    # Write four values into the FIFO
    for value in test_data:
        # Drive after rising edge, before next rising edge
        await RisingEdge(dut.wclk)
        await Timer(1, unit="ns")

        assert int(dut.wfull.value) == 0
        dut.wdata.value = value
        dut.winc.value = 1

    # Wait for the fourth write to be accepted
    await RisingEdge(dut.wclk)
    await Timer(1, unit="ns")
    dut.winc.value = 0

    # Wait for the read domain to see nonempty
    for _ in range(10):
        await RisingEdge(dut.rclk)
        await Timer(1, unit="ns")
        if int(dut.rempty.value) == 0:
            break
    else:
        assert False, "FIFO never became nonempty"

    # Read back all four values
    for expected in test_data:
        assert int(dut.rempty.value) == 0, (
            f"FIFO unexpectedly empty before reading {expected:#04x}"
        )

        actual = int(dut.rdata.value)
        assert actual == expected, (
            f"Expected {expected:#04x}, got {actual:#04x}"
        )

        # Consume the current word on the next read clock edge
        dut.rinc.value = 1
        await RisingEdge(dut.rclk)
        await Timer(1, unit="ns")
        dut.rinc.value = 0

    assert int(dut.rempty.value) == 1, (
        "FIFO should be empty after reading all four values"
    )


@cocotb.test()
async def test_fifo_full(dut):
    test_data = [
        0xA5, 0x3C, 0xF0, 0x12,
        0xB6, 0x08, 0xF9, 0xD0,
        0xE4, 0xC8, 0x75, 0x89,
        0xA1, 0xE7, 0x15, 0x43
    ]

    # Initialize inputs
    dut.wclk.value = 0
    dut.rclk.value = 0
    dut.winc.value = 0
    dut.rinc.value = 0
    dut.wdata.value = 0
    dut.wrst_n.value = 0
    dut.rrst_n.value = 0

    # Start independent clocks
    cocotb.start_soon(Clock(dut.wclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.rclk, 14, unit="ns").start())

    # Reset
    await Timer(50, unit="ns")

    assert int(dut.rempty.value) == 1
    assert int(dut.wfull.value) == 0

    dut.wrst_n.value = 1
    dut.rrst_n.value = 1

    await Timer(50, unit="ns")

    # Write 16 values
    for i, value in enumerate(test_data):
        await RisingEdge(dut.wclk)
        await Timer(1, unit="ns")

        assert int(dut.wfull.value) == 0, (
            f"FIFO became full before write {i + 1}"
        )

        dut.wdata.value = value
        dut.winc.value = 1

    # Wait for the 16th write to complete
    await RisingEdge(dut.wclk)
    await Timer(1, unit="ns")
    dut.winc.value = 0

    # Check full flag
    assert int(dut.wfull.value) == 1, (
        "FIFO should be full after 16 writes"
    )

    # Attempt a 17th write
    dut.wdata.value = 0xFF
    dut.winc.value = 1

    await RisingEdge(dut.wclk)
    await Timer(1, unit="ns")
    dut.winc.value = 0

    assert int(dut.wfull.value) == 1, (
        "FIFO should remain full after overflow attempt"
    )

    # Wait for read domain to recognize the writes
    for _ in range(10):
        await RisingEdge(dut.rclk)
        await Timer(1, unit="ns")
        if int(dut.rempty.value) == 0:
            break
    else:
        assert False, "FIFO never became nonempty"

    # Read back all 16 values
    for i, expected in enumerate(test_data):
        assert int(dut.rempty.value) == 0, (
            f"FIFO unexpectedly empty before read {i + 1}"
        )

        actual = int(dut.rdata.value)

        assert actual == expected, (
            f"Read {i + 1}: expected {expected:#04x}, "
            f"got {actual:#04x}"
        )

        dut.rinc.value = 1
        await RisingEdge(dut.rclk)
        await Timer(1, unit="ns")
        dut.rinc.value = 0

    assert int(dut.rempty.value) == 1, (
        "FIFO should be empty after 16 reads"
    )
