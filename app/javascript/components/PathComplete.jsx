import React, { useState } from 'react'
import { AutoComplete } from 'antd'
import 'antd/dist/antd.css'
import { useDB } from 'react-pouchdb'

export default () => {
  const [dataSource, setDS] = useState([])
  const [value, setValue] = useState('')
  const db = useDB('books')

  const onSelect = (value) => {
    console.info('onSelect', value)
  }

  const onSearch = async (searchText) => {
    db.allDocs({
      startkey: searchText,
      endkey: `${searchText}\uffff`,
      limit: 25,
      include_docs: true,
    })
    .then((res) => res.rows.map(
      (row) => row.doc.dir
    ))
    .then((res) => {
      console.log('res', res)
      setDS(res)
    })
  }

  const onChange = (value) => {
    setValue(value)
  }

  return <AutoComplete
    value={value}
    dataSource={dataSource}
    onSelect={onSelect}
    onSearch={onSearch}
    onChange={onChange}
    placeholder='Path?'
    style={{
      fontSize: '6ex',
      margin: 'auto',
      width: '75%',
      marginTop: '1em',
    }}
  />
}
