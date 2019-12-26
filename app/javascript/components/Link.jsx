import React from 'react'

export default (props) => {
  const { filename, filename_id } = props
  const { book_id, link_id } = props
  let action = '/links'
  let cmd = 'Link'

  const submitHandler = (evt) => {
    evt.preventDefault()
    console.info(book_id, link_id)
  }

  if(link_id) {
    action = `/links/${link_id}`
    cmd = 'Unlink'
  }

  return <React.Fragment>
    <form
      action={action}
      method='POST'
      onSubmit={submitHandler}
    >
      <input type='hidden' name='link[filename_id]' value={filename_id} />
      <input type='hidden' name='link[book_id]' value={book_id} />
      
      <label>
        <span>{filename}</span>
        <button type='submit'>{cmd}</button>
      </label>
    </form>
  </React.Fragment>
}
