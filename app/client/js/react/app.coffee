goog.provide 'app.react.App'

goog.require 'goog.dom'
goog.require 'goog.events'

class app.react.App

  ###*
    @param {app.Routes} routes
    @param {app.Title} appTitle
    @param {app.user.Store} userStore
    @param {app.songs.Store} songsStore
    @param {app.react.Header} header
    @param {app.react.Footer} footer
    @param {app.react.pages.About} aboutPage
    @param {app.react.pages.EditSong} editSongPage
    @param {app.react.pages.Me} mePage
    @param {app.react.pages.MySongs} mySongs
    @param {app.react.pages.NotFound} notFoundPage
    @param {app.react.pages.Songs} songsPage
    @param {app.react.pages.Song} songPage
    @param {app.react.pages.Trash} trashPage
    @constructor
  ###
  constructor: (routes, appTitle,
      userStore, songsStore,
      header, footer,
      aboutPage, editSongPage, mePage, mySongs, notFoundPage, songsPage,
      songPage, trashPage) ->

    {div} = React.DOM

    @component = React.createClass

      render: ->
        pageProps = {}
        page = @getActivePage pageProps

        div className: 'app active-page-' + @getPageClassName(page),
          header.component()
          page.component pageProps
          footer.component()

      getActivePage: (props) ->
        switch routes.active
          when routes.home then mySongs
          when routes.newSong then editSongPage
          when routes.songs then songsPage
          when routes.song
            props.song = songsStore.songByUrl()
            songPage
          when routes.mySong, routes.editSong
            @getLocalSongPage props
          when routes.trash then trashPage
          when routes.about then aboutPage
          when routes.me
            return notFoundPage if !userStore.isLogged()
            mePage
          else notFoundPage

      getLocalSongPage: (props) ->
        song = userStore.songByRoute routes.active
        # Local song can be removed any time, for instance in different tab.
        return notFoundPage if !song
        props.song = song
        switch routes.active
          when routes.mySong then songPage
          when routes.editSong then editSongPage

      getPageClassName: (page) ->
        switch page
          when aboutPage then 'about'
          when editSongPage then 'edit-song'
          when mePage then 'me'
          when mySongs then 'home'
          when notFoundPage then 'notfound'
          when songPage then 'song'
          when trashPage then 'trash'

      componentDidMount: ->
        goog.events.listen window, 'orientationchange', @onOrientationChange
        userStore.listen 'change', @onStoreChange

      onOrientationChange: ->
        goog.dom.getDocumentScrollElement().scrollTop = 0

      onStoreChange: ->
        @forceUpdate()

      componentDidUpdate: ->
        document.title = appTitle.get()
