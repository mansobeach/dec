import uvicorn

async def app(scope, receive, send):
   
    # http response start
    await send({
        'type': 'http.response.start',
        'status': 200,
        'headers': [
            [b'content-type', b'text/plain'],
        ],
    })
    
    # http response body
    await send({
        'type': 'http.response.body',
        'body': b'Hello, blimey !!\n',
    })

if __name__ == "__main__":
    uvicorn.run("main:app", port=5000, log_level="info")