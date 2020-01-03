import React from 'react'
import { Suspense } from 'react'
import { PouchDB, useDB } from 'react-pouchdb'
import { Alert } from 'antd'

const Descendants = () => {
  const db = useDB()

  throw db.query(
    (doc, emit) => {
      for(var i in doc.path) { 
        emit([doc.path[i], doc.path], doc) 
      }
    },
    {
      startkey: ['book', 'by'],
      endkey: ['book', 'by', {}],
    }
  )
  .then((res) => {
    console.info('RES', res)
    return (
      <ul>
        {/*
        {res.rows.map((entry) => (
          <li>{entry.dir}</li>
        ))}
        */}
      </ul>
    )
  })
  .catch((err) => {
    console.error('Map', err)
    return <Alert message='Error Mapping' banner/>
  })
}

export default () => (
  <PouchDB name='books'>
    <Suspense fallback="Loading…">
      <Descendants />
    </Suspense>
  </PouchDB>
)