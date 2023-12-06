// solc --strict-assembly Maze.yul --bin --optimize
object "Maze" {
    // Four types of sprites:
    // 0x00 => Empty
    // 0x01 => Wall
    // 0x02 => Player
    // 0x03 => Exit
    // 0xff => Invalid
    code {
        sstore(0x0, 0xffffffffffffffffffffffffffffffffffffffffff0201010101010101010101)
        sstore(0x1, 0xffffffffffffffffffffffffffffffffffffffffff0000010000000100000001)  
        sstore(0x2, 0xffffffffffffffffffffffffffffffffffffffffff0100010001000100010101)  
        sstore(0x3, 0xffffffffffffffffffffffffffffffffffffffffff0100000001000000010001)            
        sstore(0x4, 0xffffffffffffffffffffffffffffffffffffffffff0101010101000101010001)          
        sstore(0x5, 0xffffffffffffffffffffffffffffffffffffffffff0100010001000000000001)     
        sstore(0x6, 0xffffffffffffffffffffffffffffffffffffffffff0100010001000101010001)
        sstore(0x7, 0xffffffffffffffffffffffffffffffffffffffffff0100010001000100000001)
        sstore(0x8, 0xffffffffffffffffffffffffffffffffffffffffff0100010001000100010101)
        sstore(0x9, 0xffffffffffffffffffffffffffffffffffffffffff0100000000000100000003)
        sstore(0xa, 0xffffffffffffffffffffffffffffffffffffffffff0101010101010101010101)

        sstore(0xb, 0x0)
        sstore(0xc, 0x0)
        sstore(0xd, 0x0)
        sstore(0xe, 0x2)

        codecopy(0, dataoffset("Maze_Runtime"), datasize("Maze_Runtime"))
        return (0, datasize("Maze_Runtime"))
    }

    object "Maze_Runtime" {
        code {
            // return isSolved
            if eq(calldatasize(), 0x20) {
                mstore(0x0, sload(0xd))
                return (0, 0x20)
            }

            // Game starts here
            let msg_sdr := caller()

            switch msg_sdr 
            // 0x46
            case 0xF9A2C330a19e2FbFeB50fe7a7195b973bB0A3BE9 { // -y
                verbatim_0i_0o(hex"6001600c5403600c55")
            }
            // 0x75
            case 0x2ACf0D6fdaC920081A446868B2f09A8dAc797448 { // -x
                sstore(0xb, sub(sload(0xb), 1))
            }
            // 0x7a
            case 0x872917cEC8992487651Ee633DBA73bd3A9dcA309 { // +y
                verbatim_0i_0o(hex"6001600c5401600c55")
            }
            // 0x5a
            case 0x802271c02F76701929E1ea772e72783D28e4b60f { // +x
                sstore(0xb, add(sload(0xb), 1))
            }

            // can do it by using the calldata length too
            default {
                if not(iszero(sload(0xe))) {
                    sstore(0xe, sub(sload(0xe), 1))
                    let calldatalen := calldatasize()
                    if eq(calldatalen, 0x1) { 
                        sstore(0xc, sub(sload(0xc), 1)) // - y
                    }
                    if eq(calldatalen, 0x2) {
                        sstore(0xb, sub(sload(0xb), 1)) // - x
                    }
                    if eq(calldatalen, 0x3) {
                        sstore(0xc, add(sload(0xc), 1)) // + y 
                    }
                    if eq(calldatalen, 0x4) {
                        sstore(0xb, add(sload(0xb), 1)) // + x
                    }
                }
            }

            let pos_x := sload(0xb)
            let pos_y := sload(0xc)

            // check if player still in the maze
                            if gt(pos_x, 10) {
                                verbatim_0i_0o(hex"4e4f204553434150452046524f4d204d415a4521")
                            }

                            if gt(pos_y, 10) {
                                verbatim_0i_0o(hex"5448495320495320412046414b4520464c4147")
                            }


            let pos := getPos(pos_x, pos_y)


            // if player outside or on wall ==> dead
                            if or(eq(pos, 0x1), eq(pos, 0xff)) {
                                verbatim_0i_0o(hex"4556454e204d4152494f2043414e4e4f542048495420544849532057414c4c")
                            }

            if eq(pos, 0x3) {
                verbatim_0i_0o(hex"6001600d5500")
            }

            // Function restructured to logically align x and y
            function getPos(x, y) -> type_ {
                type_ := and(shr(mul(8, sub(10, x)), sload(y)), 0xff)
            }

            // Original source function
            /* function getPos(y, x) -> type_ {
                type_ := and(shr(mul(8, sub(10, y)), sload(x)), 0xff)
            } */
        }
    }
}