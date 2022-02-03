import os
from typing import List
import databases
import requests
import sqlalchemy
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI()

origins = [
    'http://localhost',
    'http://localhost:8000',
    'http://localhost:9000',
    '*',
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

DATABASE_URL = os.environ.get('DATABASE_URL',
                              'postgres://postgres:postgres@db:5432/news')
JOKES_API_URL = os.environ.get('JOKES_API_URL', "https://v2.jokeapi.dev/joke/any")

database = databases.Database(DATABASE_URL)

metadata = sqlalchemy.MetaData()

news = sqlalchemy.Table(
    'news',
    metadata,
    sqlalchemy.Column('id', sqlalchemy.Integer, primary_key=True),
    sqlalchemy.Column('title', sqlalchemy.String),
    sqlalchemy.Column('short_description', sqlalchemy.String),
    sqlalchemy.Column('description', sqlalchemy.String),
    sqlalchemy.Column('preview', sqlalchemy.String),
)

engine = sqlalchemy.create_engine(
    DATABASE_URL
)
metadata.create_all(engine)


class ShortNote(BaseModel):
    id: int
    title: str
    short_description: str
    preview: str


class Note(BaseModel):
    id: int
    title: str
    short_description: str
    description: str
    preview: str


async def fill_db():
    news_objects = await database.fetch_all(news.select())
    if news_objects:
        return
    news_objects = []
    for i in range(3):
        joke_text = ''
        joke_category = ''
        response = requests.get(JOKES_API_URL, verify=False)
        if response.status_code == 200:
            joke = response.json()
            if joke['type'] == 'single':
                joke_text = joke['joke']
            elif joke['type'] == 'twopart':
                joke_text = f"{joke['setup']} {joke['delivery']}"
            joke_category = joke['category']
        else:
            joke_text = "Error loading joke"

        news_objects.append({'title': f'Joke {i}',
                             'short_description': joke_text,
                             'description': f'Category: {joke_category}; Content: {joke_text}',
                             'preview': '/static/image.png'})
    query = news.insert()
    await database.execute_many(query=query, values=news_objects)


@app.on_event('startup')
async def startup():
    await database.connect()
    await fill_db()


@app.on_event('shutdown')
async def shutdown():
    await database.disconnect()


@app.get('/api/news/', response_model=List[ShortNote])
async def get_news():
    return await database.fetch_all(news.select())


@app.get('/api/news/{new_id}', response_model=Note)
async def read_item(new_id: int):
    return await database.fetch_one(news.select().where(news.c.id == new_id))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
