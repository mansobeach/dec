# DB CRUD function

from sqlalchemy.orm import Session

from . import models, schemas

def get_subscriptions(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Subscription).offset(skip).limit(limit).all()


# -----------------------------------------------------------------------------

def create_subscription(db: Session, subscription: schemas.SubscriptionCreate):
    
    print("create_subscription: Id                      => {}".format(subscription.Id))
    print("create_subscription: Status                  => {}".format(subscription.Status))
    print("create_subscription: NotificationEndpoint    => {}".format(subscription.NotificationEndpoint))
    print("create_subscription: NotificationEpUsername  => {}".format(subscription.NotificationEpUsername))
    print("create_subscription: NotificationEpPassword  => {}".format(subscription.NotificationEpPassword))
    print("create_subscription: LastNotificationDate    => {}".format(subscription.LastNotificationDate))

    db_subscription = models.Subscription(Id                        = subscription.Id, \
                                          Status                    = subscription.Status, \
                                          FilterParam               = subscription.FilterParam, \
                                          NotificationEndpoint      = subscription.NotificationEndpoint, \
                                          NotificationEpUsername    = subscription.NotificationEpUsername, \
                                          NotificationEpPassword    = subscription.NotificationEpPassword, \
                                          SubmissionDate            = subscription.SubmissionDate, \
                                          LastNotificationDate      = subscription.LastNotificationDate
                                            )
    db.add(db_subscription)
    db.commit()
    db.refresh(db_subscription)
    return db_subscription

# -----------------------------------------------------------------------------

def get_subscription(db: Session, subscription: schemas.SubscriptionId):
    return db.query(models.Subscription).filter(models.Subscription.Id == subscription.Id)

# -----------------------------------------------------------------------------


def update_subscription_status(db: Session, subscription_status: schemas.SubscriptionStatus):
    db.query(models.Subscription).filter(models.Subscription.Id == subscription_status.Id).update( {models.Subscription.Status : subscription_status.Status} )
    db.commit()
    db.flush()

# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------



def create_product(db: Session, product: schemas.ProductCreate):
    print("create_product: {}".format(product.Name))
    db_product = models.Product(Name            = product.Name, \
                                ContentType     = product.ContentType, \
                                ContentLength   = product.ContentLength )
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

# -----------------------------------------------------------------------------