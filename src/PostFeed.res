let s = React.string

open Belt

type state = {posts: array<Post.t>, forDeletion: Map.String.t<Js.Global.timeoutId>}

type action =
  | DeleteLater(Post.t, Js.Global.timeoutId)
  | DeleteAbort(Post.t)
  | DeleteNow(Post.t)

let reducer = (state, action) =>
  switch action {
  | DeleteLater(post, timeoutId) => {
      posts: state.posts,
      forDeletion: state.forDeletion->Belt.Map.String.set(post.id, timeoutId),
    }
  | DeleteAbort(post) => {
      posts: state.posts,
      forDeletion: state.forDeletion->Belt.Map.String.remove(post.id),
    }
  | DeleteNow(post) => {
      posts: Js.Array.filter(existing_post => existing_post->Post.id != post.id, state.posts),
      forDeletion: state.forDeletion->Belt.Map.String.remove(post.id),
    }
  }

let initialState = {posts: Post.examples, forDeletion: Map.String.empty}

module PostView = {
  @react.component
  let make = (~post, ~handleClick, ~postText) => {
    <div
      className="bg-green-200 hover:bg-green-300 text-gray-800 hover:text-gray-900 px-8 py-4 mb-4 rounded">
      <h2 className="text-2xl mb-1"> {s(post.Post.title)} </h2>
      <h3 className="mb-4"> {s(post.author)} </h3>
      {React.array(postText(post.text))}
      <button
        className="mr-4 mt-4 bg-red-600 hover:bg-red-700 text-white py-2 px-4 "
        onClick={_mouseEvt => {
          handleClick(_mouseEvt)
        }}>
        {s("Remove this post")}
      </button>
    </div>
  }
}

module DeleteNotificationView = {
  @react.component
  let make = (~post, ~handleClickRestore, ~handleClickDeleteImmediate) => {
    <div className="relative bg-yellow-100 px-8 py-4 mb-4 h-40">
      <p className="text-center white mb-1">
        {s({
          `This post from ${post.Post.title} by ${post.author} will be permanently removed in 10 seconds.`
        })}
      </p>
      <div className="flex justify-center">
        <button
          onClick={_mouseEvt => {
            handleClickRestore(_mouseEvt)
          }}
          className="mr-4 mt-4 bg-yellow-500 hover:bg-yellow-900 text-white py-2 px-4">
          {s("Restore")}
        </button>
        <button
          onClick={_mouseEvt => {
            handleClickDeleteImmediate(_mouseEvt)
          }}
          className="mr-4 mt-4 bg-red-600 hover:bg-red-700 text-white py-2 px-4">
          {s("Delete Immediately")}
        </button>
      </div>
      <div className="bg-red-600 h-2 w-full absolute top-0 left-0 progress" />
    </div>
  }
}

@react.component
let make = () => {
  let (state, dispatch) = React.useReducer(reducer, initialState)

  let posts = state.posts->Belt.Array.map(post => {
    if state.forDeletion->Belt.Map.String.has(post.id) {
      let handleClickRestore = _evt => {
        state.forDeletion->Belt.Map.String.getExn(post.id)->Js.Global.clearTimeout
        dispatch(DeleteAbort(post))
      }

      let handleClickDeleteImmediate = _evt => {
        state.forDeletion->Belt.Map.String.getExn(post.id)->Js.Global.clearTimeout
        dispatch(DeleteNow(post))
      }

      <DeleteNotificationView post handleClickRestore handleClickDeleteImmediate key={post.id} />
    } else {
      let postText = text => {
        text->Belt.Array.map(line => <p className="mb-1 text-sm"> {s(line)} </p>)
      }

      let handleClick = _evt => {
        let timeoutId = Js.Global.setTimeout(() => {
          dispatch(DeleteNow(post))
        }, 10000)
        dispatch(DeleteLater(post, timeoutId))
      }

      <PostView post handleClick postText key={post.id} />
    }
  })

  {React.array(posts)}
}
