module Update exposing (update)

import RemoteData exposing (RemoteData(Loading, NotAsked), WebData)
import Action exposing (Msg(..))
import Ask exposing (ask)
import Formo exposing (blurElement, elementValue, focusElement, updateElementValue, validateForm)
import Model exposing (Flags, Model, init)
import App.Api exposing (createApp)
import App.Model exposing (initAppForm)
import Route
import Rule.Api exposing (deleteRule)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AppFormBlur field ->
            ( { model | appForm = blurElement model.appForm field }, Cmd.none )

        AppFormClear ->
            ( { model | appForm = initAppForm }, Cmd.none )

        AppFormFocus field ->
            ( { model | appForm = focusElement model.appForm field }, Cmd.none )

        AppFormSubmit ->
            let
                ( form, isValid ) =
                    validateForm model.appForm
            in
                case isValid of
                    True ->
                        ( { model | newApp = Loading }, Cmd.map NewApp (createApp (elementValue model.appForm "name") (elementValue model.appForm "description")) )

                    False ->
                        ( { model | appForm = form }, Cmd.none )

        AppFormUpdate field value ->
            ( { model | appForm = updateElementValue model.appForm field value }, Cmd.none )

        FetchApp response ->
            ( { model | app = response }, Cmd.none )

        FetchApps response ->
            ( { model | app = NotAsked, apps = response }, Cmd.none )

        FetchRule response ->
            ( { model | rule = response }, Cmd.none )

        FetchRules response ->
            ( { model | rules = response }, Cmd.none )

        LocationChange location ->
            init (Flags model.zone) location

        Navigate route ->
            ( model, Cmd.map LocationChange (Route.navigate route) )

        NewApp response ->
            ( { model | appForm = initAppForm, apps = (appendWebData model.apps response), newApp = NotAsked }, Cmd.none )

        RuleDeleteAsk id ->
            ( model, ask id )

        RuleDeleteConfirm id ->
            ( model, Cmd.map RuleDelete (deleteRule model.appId id) )

        RuleDelete _ ->
            ( model, Cmd.map LocationChange (Route.navigate (Route.Rules model.appId)) )

        Tick time ->
            let
                startTime =
                    if model.startTime == 0 then
                        time
                    else
                        model.startTime
            in
                ( { model | startTime = startTime, time = time }, Cmd.none )



-- HELPER


appendWebData : WebData (List a) -> WebData a -> WebData (List a)
appendWebData list single =
    case (RemoteData.toMaybe single) of
        Nothing ->
            list

        Just a ->
            case (RemoteData.toMaybe list) of
                Nothing ->
                    RemoteData.succeed [ a ]

                Just list ->
                    RemoteData.succeed (list ++ [ a ])
