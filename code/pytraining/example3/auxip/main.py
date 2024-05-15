# https://fastapi.tiangolo.com/tutorial/sql-databases/
# https://stackoverflow.com/questions/59929028/python-fastapi-error-422-with-post-request-when-sending-json-data
# https://fastapi-utils.davidmontague.xyz/user-guide/basics/guid-type/

import uvicorn

from typing import Any, Annotated, Optional

from fastapi.openapi.utils import get_openapi
from fastapi import Depends, FastAPI, Request, HTTPException, status
from fastapi.responses import FileResponse

from sqlalchemy.orm import Session

# application specific
from . import crud, models, schemas
from .database import SessionLocal, engine


import logging
logging.basicConfig(level=logging.INFO, format="%(levelname)-9s %(asctime)s - %(name)s - %(message)s")
logger = logging.getLogger(__name__)


# create the db model
# it should be done outside with alembic

logger.info("Creating database => models.Base.metadata.create_all(bind=engine)")
models.Base.metadata.create_all(bind=engine)

tags_metadata = [
    {
        "name": "Subscriptions",
        "description": "Operations with Subscriptions",
    },
    {
        "name": "Products",
        "description": "Products",
        "externalDocs": {
            "description": "Items external docs",
            "url": "https://fastapi.tiangolo.com/",
        },
    },
]

app = FastAPI(openapi_tags = tags_metadata)



# https://fastapi.tiangolo.com/how-to/extending-openapi/
app.title           = "Auxiliary Data Gathering Service"
app.summary         = "AUXIP description"
app.version         = "0.0.1"
app.description     = "Here's a longer description of the custom **ADGS** service"

list_subscription=[]

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# -------------------------------------------------------------------

from pydantic import BaseModel, Field, create_model

query_params    = {"$count": (bool, True)}
query_model     = create_model("Query", **query_params)






# -------------------------------------------------------------------


# -------------------------------------------------------------------

'''
    AUXIP Create Subscription
'''

@app.post("/odata/v1/Subscription", tags=["Subscriptions"], status_code = status.HTTP_201_CREATED, response_model = schemas.SubscriptionOutput) #, response_model_by_alias=False)
async def create_subscription(subscription: schemas.Subscription, db: Session = Depends(get_db)) -> Any:
    """
    Create a Subscription with the following parameters:

    - **FilterParam**: The filter parameters of the Subscription (refers to the $filter= parameter of any Products? query)
    - **NotificationEndpoint**: URI used by the AUXIP for subscription notifications
    - **NotificationEpUsername**: The username associated with the EndPoint URI provided
    - **NotificationEpPassword**: The password associated with the EndPoint URI provided
    - **Status**: SubscriptionStatus value: running (0) paused (1) cancelled (2)
    """
    print("/post create_subscription")
    print(subscription)

    list_subscription.append(subscription)

    return crud.create_subscription(db = db, subscription = subscription)

# --------------------------------------------------------------------

'''
    AUXIP Update Subscription Status
'''

@app.put("/odata/v1/Subscription/Status", tags=["Subscriptions"])
async def update_subscription_status(subscription_status: schemas.SubscriptionStatus, db: Session = Depends(get_db)) -> Any:
    print("/put update subscription status")
    print(subscription_status)
    return crud.update_subscription_status(db = db, subscription_status = subscription_status)
    
# --------------------------------------------------------------------


# --------------------------------------------------------------------

# get ADGS Subscriptions

@app.get("/odata/v1/Subscription", tags=["Subscriptions"], response_model = schemas.SubscriptionOutput)
async def get_subcription(subscription_id: schemas.SubscriptionId):
    return list_subscription

# --------------------------------------------------------------------


class Product(BaseModel):
    name: str = Field(alias='Name')
    class Config:
        
        orm_mode = True

        schema_extra = {
            "example": {
                "Name": "AMV_ERRMAT"
            }
        }
   

@app.get("/Products") #, response_model=list[Product])
async def read_products(q: str | None = None):
    print(q)
    results = {"Products": [{"Name": "AMH_ERRMAT"}, {"Name": "AMH_ERRMAT"}]}
    if q:
        logger.info("{}".format(q))
        results.update({"q": q})
    return results


# --------------------------------------------------------------------

@app.get("/odata/v0/Products")
async def count_products(params: query_model = Depends()):
    params_as_dict = params.dict()
    logger.info(params_as_dict)
    return 667

'''

class CountModel(BaseModel):
	count: Optional[bool] = Field(alias="$count", default=True)
'''

@app.get("/odata/v1/Products")
async def count_products(request: Request):
    print(request['path'])
    params = request.query_params
    print(params)
    print(request.query_params['$count'])
    return 666



favicon_path = 'fastapi.svg'

@app.get('/favicon.ico', include_in_schema=False)
async def favicon():
    return FileResponse(favicon_path)

# --------------------------------------------------------------------

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port = 8000, reload = True, debug = True)
