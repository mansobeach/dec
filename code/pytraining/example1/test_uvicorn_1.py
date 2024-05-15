import uvicorn

async def app(scope, receive, send):
   
    await send({
        'type': 'http.response.start',
        'status': 401,
        'headers': [
            [b'content-type', b'text/plain'],
        ],
    })

    '''
    
    await send({
        'type': 'http.response.body',
        'body': b'Hello, blimey!',
    })

    '''

if __name__ == "__main__":
    uvicorn.run("main:app", port=5000, log_level="info")