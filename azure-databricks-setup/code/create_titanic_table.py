# Databricks resource source to create the Titanic passengers table (since using the )
spark.sql("""
CREATE EXTERNAL TABLE IF NOT EXISTS default.titanic_passengers_raw (
    PassengerId INT,    
    Survived INT,
    Pclass INT,
    Name STRING,
    Sex STRING,
    Age INT,
    SibSp INT,
    Parch INT,
    Ticket STRING,
    Fare FLOAT,
    Cabin STRING,
    Embarked STRING
)
USING CSV
OPTIONS (
    header 'true',
    inferSchema 'true'
)
LOCATION '/mnt/data/titanic_passengers_raw.csv'
COMMENT 'Titanic passengers dataset'
""")