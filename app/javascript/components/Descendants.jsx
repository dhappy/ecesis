import React from 'react'
import { Suspense } from 'react'
import { PouchDB, useDB } from 'react-pouchdb'
import { Alert } from 'antd'

let data = null

const getDescendants = () => {
  const db = useDB()

  if(data !== null) {
    return data
  } else {
    throw db.query(
      'tree/descendants',
      {
        startkey: ['book', 'by'],
        endkey: ['book', 'by', {}],
      }
    )
    .then((res) => res.rows)
    .then((rows) => data = rows)
  }
}

const Descendants = () => {
  const desc = getDescendants()

  return (
    <ul>
      {desc.map((entry) => (
        <li>{entry.dir}</li>
      ))}
    </ul>
  )
}

export default () => (
  <PouchDB name='books'>
    <Suspense fallback={<Alert message='Loading Descendants…'/>}>
      <Descendants />
    </Suspense>
  </PouchDB>
)