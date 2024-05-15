# > Pydantic models
# > Create an SubscriptionBase Pydantic models (or let's say "schemas") to have common attributes while creating or reading data
# > Create an SubcriptionCreate that inherit from them (so they will have the same attributes), plus any additional data (attributes) needed for creation

import uuid
import enum
from datetime import datetime
from typing import Optional, Union, ClassVar
from pydantic import BaseModel, ConfigDict, PrivateAttr, Field
from uuid import UUID, uuid4

class EnumSubscriptionStatus(str, enum.Enum):
    running     = 0
    paused      = 1
    cancelled   = 2

class SubscriptionStatus(BaseModel):
    Id                      :   UUID
    Status                  :   EnumSubscriptionStatus

class SubscriptionId(BaseModel):
    Id                      :   UUID

class SubscriptionBase(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    Id                      :   UUID = Field(default_factory=uuid4)
    SubmissionDate          :   datetime = Field(default = datetime.now(), example="2024-12-31T14:30:00")
    LastNotificationDate    :   datetime = Field(default = datetime.now(), example="2024-12-31T14:30:00")
    # LastNotificationDate    :   Optional[datetime]
    # LastNotificationDate    : Union[datetime, None] = None
    # LastNotificationDate    :   datetime = Field(nullable=True)
    Status                  :   EnumSubscriptionStatus
    FilterParam             :   str
    NotificationEndpoint    :   str
    NotificationEpUsername  :   str
    NotificationEpPassword  :   str

class SubscriptionOutput(SubscriptionBase):
    Id              : uuid
    # SubmissionDate          : datetime = Field(default = datetime.now(), example="2024-12-31T14:30:00")
    # LastNotificationDate    : Optional[datetime]
    # LastNotificationDate    :   datetime = Field(nullable=True)
    # LastNotificationDate    : Union[datetime, None] = None
    class Config:
        orm_mode                = True
        use_enum_values         = True
        arbitrary_types_allowed = True
       
        json_schema_extra = {
            "example": {
                "Id"                        : "9f297871-af1a-4daf-b276-7c8b89d7ff42",
                "SubmissionDate"            : "2024-12-31T14:30:00",
                "LastNotificationDate"      : "null",
                "Status"                    : "0",
                "FilterParam"               : "contains(Name,'_AUX_ECMWFD_') and PublicationDate gt 2019-02-01T00:00:00.000Z and PublicationDate lt 2019-09-01T00:00:00.000Z",
                "NotificationEndpoint"      : "http://myserver.org",
                "NotificationEpUsername"    : "pinocchio",
                "NotificationEpPassword"    : "diLegno$"
            }
        }

class SubscriptionCreate(SubscriptionBase):
    pass

class Subscription(SubscriptionBase):
    class Config:
        orm_mode                = True
        use_enum_values         = True
        arbitrary_types_allowed = True
       
        json_schema_extra = {
            "example": {
                "Status"                    : "0",
                "FilterParam"               : "contains(Name,'_AUX_ECMWFD_') and PublicationDate gt 2019-02-01T00:00:00.000Z and PublicationDate lt 2019-09-01T00:00:00.000Z",
                "NotificationEndpoint"      : "http://myserver.org",
                "NotificationEpUsername"    : "pinocchio",
                "NotificationEpPassword"    : "diLegno$"
            }
        }


# -----------------------------------------------------------------------------

class ProductBase(BaseModel):
    # name: str  = Field(alias='Name')
    Name: str
    ContentType: str
    ContentLength: int
    
class ProductCreate(ProductBase):
    pass


class Product(ProductBase):
    class ConfigProduct:
        orm_mode = True
        
        json_schema_extra = {
            "example": {
                "Name"          : "S2__OPER_AUX_ECMWFD_PDMC_20190216T120000_V20190217T090000_20190217T210000.TGZ",
                "ContentType"   : 'application/octet-stream',
                "ContentLength" : '8326253'
            }
        }
        
