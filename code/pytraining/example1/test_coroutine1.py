import asyncio
import time

async def myfunction(i):
    print('In myfunction', i)
    time.sleep(2)

async def main():
    # why index should start in 0
    # https://www.cs.utexas.edu/users/EWD/ewd08xx/EWD831.PDF
    print("START main\n")
    for i in range(0,6):
        print(i)
        print('await myfunction ', i)
        await myfunction(i)
        print('In main', i)
    print("END main\n")
    
asyncio.run(main())