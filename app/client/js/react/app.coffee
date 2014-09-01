goog.provide 'app.react.App'

goog.require 'goog.dom'
goog.require 'goog.events'

class app.react.App

  ###*
    @param {app.user.Store} userStore
    @param {app.Routes} routes
    @param {app.Title} appTitle
    @param {app.react.Header} header
    @param {app.react.Footer} footer
    @param {app.react.pages.MySongs} mySongs
    @param {app.react.pages.EditSong} editSongPage
    @param {app.react.pages.Song} songPage
    @param {app.react.pages.NotFound} notFoundPage
    @param {app.react.pages.Trash} trashPage
    @constructor
  ###
  constructor: (userStore, routes, appTitle,
      header, footer,
      mySongs, editSongPage, songPage, notFoundPage, trashPage) ->

    {div} = React.DOM

    @component = React.createClass

      render: ->
        pageProps = {}
        page = @page pageProps

        div className: 'app active-page-' + @pageClassName(page),
          header.component()
          page.component pageProps
          footer.component()

      page: (props) ->
        switch routes.active
          when routes.home then mySongs
          when routes.newSong then editSongPage
          when routes.mySong, routes.editSong
            song = userStore.songByRoute routes.active
            return notFoundPage if !song
            props.song = song
            switch routes.active
              when routes.mySong then songPage
              when routes.editSong then editSongPage
          when routes.trash then trashPage
          else notFoundPage

      pageClassName: (page) ->
        switch page
          when mySongs then 'home'
          when editSongPage then 'edit-song'
          when songPage then 'song'
          when trashPage then 'trash'
          when notFoundPage then 'notfound'

      componentDidMount: ->
        goog.events.listen window, 'orientationchange', @onOrientationChange
        userStore.listen 'change', @onStoreChange

      onOrientationChange: ->
        goog.dom.getDocumentScrollElement().scrollTop = 0

      onStoreChange: ->
        @forceUpdate()

      componentDidUpdate: ->
        document.title = appTitle.get()
