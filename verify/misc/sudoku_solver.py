from subprocess import Popen, PIPE

def verify(cmd, puzzle):
    proc = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate(bytes(' '.join(c for c in puzzle), 'utf-8'))
    status = True
    if err != b'':
        print("Did not expect anything on stderr")
        status = False
    s = out.decode('utf-8').split('\n')
    if s[0] != "Solving sudoku n# 0" or s[1] != "Done reading sudoku...":
        print("Header not properly printed")
        status = False
    if s[11] != "Solved !":
        print("Solution not announced")
        status = False
    unsolved = "".join(s[2:11]).replace(' ', '')
    solved = "".join(s[12:21]).replace(' ', '')
    if unsolved != puzzle:
        print("Error reading data")
        status = False
    for (c,d) in zip(unsolved, solved):
        if c != '0' and c != d:
            print("Nonzero value changed")
            status = False
        if not ('1' <= d <= '9'):
            print("Value out of range")
            status = False
    for i in range(9):
        if len(set(solved[i*9+j] for j in range(9))) != 9:
            print("Duplicate number in line")
            status = False
        if len(set(solved[j*9+i] for j in range(9))) != 9:
            print("Duplicate number in column")
            status = False
    for si in range(3):
        for sj in range(3):
            if len(set(solved[(3*si+i)*9 + (3*sj+j)] for i in range(3) for j in range(3))) != 9:
                print("Duplicate number in block")
                status = False
    if not status: print(out)
    return status


cfg = [
    ["001900003900700160030005007050000009004302600200000070600100030042007006500006800"],
    ["000125400008400000420800000030000095060902010510000060000003049000007200001298000"],
    ["062340750100005600570000040000094800400000006005830000030000091006400007059083260"],
    ["300000000005009000200504000020000700160000058704310600000890100000067080000005437"],
    ["630000000000500008005674000000020000003401020000000345000007004080300902947100080"],
    ["000020040008035000000070602031046970200000000000501203049000730000000010800004000"],
    ["361025900080960010400000057008000471000603000259000800740000005020018060005470329"],
    ["050807020600010090702540006070020301504000908103080070900076205060090003080103040"],
    ["080005000000003457000070809060400903007010500408007020901020000842300000000100080"],
    ["003502900000040000106000305900251008070408030800763001308000104000020000005104800"],
]
