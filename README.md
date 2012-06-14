
#### Small Sinatra App for Foundry OAuth

## Running Locally
To try this app out locally, you can just use the default credentials supplied.  They work fine for local development

    bundle install
    export ATT_CLIENT_ID=<<client_id>>
    export ATT_CLIENT_SECRET=<<secret>> 
    rackup config.ru -p 4567
    
## To deploy to heroku,
git clone this repo, 
then create the app on heroku

    git clone https://github.com/ztsyed/foundry-oauth.git foundry-oauth
    cd  foundry-oauth
    heroku create
    heroku config:add ATT_CLIENT_ID=<<client_id>> ATT_CLIENT_SECRET=<<secret>>  ATT_REDIRECT_URI=http://foundry-oauth-example.heroku.com/users/att/callback
    git push heroku
    heroku open
    
and  then try out the app
