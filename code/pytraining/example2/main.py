# 


import uvicorn



import uuid

from typing import Annotated, Optional

from dataclasses import dataclass

from pydantic import BaseModel, Field

# FASTAPI
from fastapi import FastAPI, Request, Depends, Path, Query, Body


import logging
logging.basicConfig(level=logging.INFO, format="%(levelname)-9s %(asctime)s - %(name)s - %(message)s")
logger = logging.getLogger(__name__)

# SQLALCHEMY  / CONNECTION DB / SQLITE3 model / SESSION
from sqlalchemy import create_engine
from sqlalchemy.dialects.sqlite import *
from sqlalchemy.orm import sessionmaker

SQLALCHEMY_DATABASE_URL = "sqlite:///./mydata.sqlite3"
db_engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})


# -----------------------------------------------------
# SQLALCHEMY / MODEL
from sqlalchemy import Column, Integer, Float, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.dialects.postgresql import UUID

from fastapi_utils.guid_type import GUID, GUID_SERVER_DEFAULT_POSTGRESQL, GUID_DEFAULT_SQLITE

Base = declarative_base()

class SubscriptionDB(Base):
    __tablename__   = 'subscriptions'
    
    # Question: is it worthy make uuid as PK ?
    # subscription_id = Column(GUID, primary_key = True, nullable = False, server_default = GUID_DEFAULT_SQLITE)
    id              = Column(Integer, primary_key = True, autoincrement = True, nullable = False)
    filter_param    = Column(String(63), unique = True)
    end_point       = Column(String(63), unique = False)
    username        = Column(String(63), unique = False)
    password        = Column(String(63), unique = False)

# create DB
Base.metadata.create_all(bind=db_engine)

# ----------------------------------------------------------------------------
# create DB session
Session = sessionmaker(autocommit = True, autoflush = True, bind = db_engine)

def get_db():
    db = session()
    try:
        yield db
    finally:
        db.close()

# session = Session()

# ----------------------------------------------------------------------------


# FastAPI object
app = FastAPI()


#str(uuid.uuid4())

@dataclass
class Subscription_OLD:
    subscription_id:int
    filter_param:str
    end_point:str
    username:str
    password:str


# --------------------------------------------------------------------

class Subscription(BaseModel):
    subscription_id:int
    filter_param:str
    end_point:str
    username:str
    password:str

    class Config:
        
        # to construct the Model from SQLAlchemy
        orm_mode = True

        schema_extra = {
            "example": {
                "subscription_id": str(uuid.uuid4()),
                "filter_param": "contains",
                "end_point": "http://myserver.com",
                "username": "pinocchio",
                "password": "pinocchio"
            }
        }

# --------------------------------------------------------------------


# --------------------------------------------------------------------

class ODataModel(BaseModel):
	count: Optional[bool] = Field(alias="$count", default=True)

# --------------------------------------------------------------------



@app.get("/")
async def index():
    return {"message": "Hello blimey !"}

# -------------------------------------------------------------------

@app.get("/odata/v1/Products/{name}")
async def product(name:str, id:Optional[int]=None):
    return {"name":name, "id":id}

# -------------------------------------------------------------------

# $count

@app.get("/odata/v1/Products")
async def count_products(count:bool):

    # To get the alias of the variable name
    # alias_count = ODataModel.__fields__["count"].alias
    # LOGGER.info(f"alias of count: {alias_count}")

    if count == True:
        return 1321
    
    if count == False:
        return 0


# -------------------------------------------------------------------

@app.get("/odata/v1/Products/$count")
async def count_products(count:bool):
    if count == True:
        return 1321
    
    if count == False:
        return 0

# -------------------------------------------------------------------

# check this "Annotated" from typing
# https://stackoverflow.com/questions/30957385/why-24-is-showing-in-url
# https://stackoverflow.com/questions/65370184/using-special-characters-with-variables

@app.get("/items/")
async def read_items(q: Annotated[list[str], Query()] = ["$count"]):
    # query_items = {"q": q}
    return 666666



# --------------------------------------------------------------------

# POST example

list_subscription=[]


@app.post("/odata/v1/Subscriptions_OLD")
async def addsubcription_old(request: Request, subscription_id:int = Body(), filter_param:str = Body(), end_point:str = Body(), username:str =Body(), password:str = Body()):
    subscription={'ID':str(uuid.uuid4()), 'FilterParam':filter_param,  'NotificationEndPoint':end_point, 'NotificationEPUsername':username, 'NotificationEpPassword':password}
    return subscription



# --------------------------------------------------------------------

@app.post("/odata/v1/Subscriptions", response_model = Subscription)
async def addsubcription(subscription:Subscription, db: Session = Depends(get_db)):

    db_subscription = Subscription(**subscription.dict() )

    db.add(db_subscription)
           
    db.commit()

    db.refresh(db_subscription)

    # subscription.subscription_id = str(uuid.uuid4())
    # subscription={'ID':str(uuid.uuid4()), 'FilterParam':filter_param,  'NotificationEndPoint':end_point, 'NotificationEPUsername':username, 'NotificationEpPassword':password}
    list_subscription.append(subscription)
    return subscription

# --------------------------------------------------------------------

# get ADGS Subscriptions

@app.get("/odata/v1/Subscriptions")
async def get_subcription():
    return list_subscription

# --------------------------------------------------------------------



if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port = 8000, reload = True)


# https://stackoverflow.com/questions/70028609/changing-pydantic-model-field-arguments-with-class-variables-for-fastapi
# https://stackoverflow.com/questions/75998227/how-to-define-query-parameters-using-pydantic-model-in-fastapi
# https://fastapi.tiangolo.com/advanced/settings/


# https://tejaksha-k.medium.com/exploring-mongodb-functions-a-comprehensive-guide-eb336b00d3a2