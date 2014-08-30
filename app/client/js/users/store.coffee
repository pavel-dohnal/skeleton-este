goog.provide 'app.user.Store'

goog.require 'app.songs.Song'
goog.require 'este.labs.Store'
goog.require 'goog.array'

class app.user.Store extends este.labs.Store

  ###*
    @constructor
    @extends {este.labs.Store}
  ###
  constructor: ->
    super 'user'
    @setEmpty()

  ###*
    @type {app.songs.Song}
  ###
  newSong: null

  ###*
    @type {Array.<app.songs.Song>}
  ###
  songs: null

  ###*
    @type {Object} Auth user.
  ###
  user: null

  setEmpty: ->
    @newSong = new app.songs.Song
    @songs = []
    @user = null

  ###*
    @return {Array.<app.songs.Song>}
  ###
  songsSortedByName: ->
    songs = @songs.slice 0
    goog.array.sortObjectsByKey songs, 'name'
    songs

  ###*
    @return {Array.<app.ValidationError>}
  ###
  addNewSong: ->
    errors = @newSong.validate()
    if @contains @newSong
      errors.push new app.ValidationError 'name',
        'Song with such name and artist already exists.'
    return errors if errors.length
    @songs.push @newSong
    @newSong = new app.songs.Song
    @notify()
    []

  ###*
    @param {app.songs.Song} song
  ###
  delete: (song) ->
    goog.array.remove @songs, song
    @notify()

  ###*
    @param {string} id
    @return {app.songs.Song}
  ###
  songById: (id) ->
    goog.array.find @songs, (song) -> song.id == id

  ###*
    @param {este.Route} route
    @return {app.songs.Song}
  ###
  songByRoute: (route) ->
    @songById route.params.id

  ###*
    @param {app.songs.Song} song
    @return {boolean}
  ###
  contains: (song) ->
    goog.array.some @songs, (s) ->
      s.name == song.name &&
      s.artist == song.artist

  ###*
    @param {app.songs.Song} song
    @param {string} prop
    @param {string} value
  ###
  updateSong: (song, prop, value) ->
    song[prop] = value
    song.update()
    @notify()

  ###*
    @override
  ###
  toJson: ->
    newSong: @newSong
    songs: @asObject @songs
    user: @user

  ###*
    @override
  ###
  fromJson: (json) ->
    @newSong = @instanceFromJson app.songs.Song, json.newSong
    @songs = @asArray(json.songs || []).map @instanceFromJson app.songs.Song
    @user = json.user

  ###*
    @param {Object} serverJson
    @param {Object} user Auth user.
  ###
  mergeServerChanges: (serverJson, user) ->
    console.log 'mergeServerChanges' if goog.DEBUG
    @mergeUser serverJson.user, user
    localJson = @toJson()
    if serverJson.songs
      @mergeSongs localJson.songs, serverJson.songs
    @fromJson localJson

  ###*
    @param {Object} appUser
    @param {Object} authUser
  ###
  mergeUser: (appUser, authUser) ->
    # Always prefer thirdparty auth user.
    @user = @authUserToAppUser authUser
    # Except createdAt.
    @user.createdAt = appUser.createdAt

  ###*
    @param {Object} authUser Auth user.
    @return {Object} user App user.
  ###
  authUserToAppUser: (authUser) ->
    displayName: authUser.displayName
    id: authUser.id
    provider: authUser.provider
    thirdPartyUserData: authUser.thirdPartyUserData
    uid: authUser.uid

  ###*
    @param {Object} localSongs
    @param {Object} serverSongs
  ###
  mergeSongs: (localSongs, serverSongs) ->
    for serverSongId, serverSong of serverSongs
      localSong = localSongs[serverSongId]
      if !localSong
        localSongs[serverSongId] = serverSong
        continue
      @mergeSong localSong, serverSong
    return

  ###*
    For now, server song always override local one.
    @param {Object} localSong
    @param {Object} serverSong
  ###
  mergeSong: (localSong, serverSong) ->
    localSong.name = serverSong.name
    localSong.artist = serverSong.artist
    localSong.lyrics = serverSong.lyrics

  ###*
    @param {boolean} userWasLogged
  ###
  clearOnLogout: (userWasLogged) ->
    if userWasLogged
      @setEmpty()
    else
      @user = null
