
Small Sinatra App for Foundry OAuth

To try this app out locally, you can just use the default credentials supplied.  They work fine for local development

    bundle install
    rackup config.ru -p 4567
    
To deploy to heroku,
git clone this repo, 
then create the app on heroku

    git clone git@gist.github.com:95ead624c7085f3221a2.git gist-95ead624
    cd  gist-95ead624
    heroku create
    heroku config:add ATT_CLIENT_ID=e7e7bb45cea4589942c50221d7e9c449 ATT_CLIENT_SECRET=7cc8ac11dbfde28b  ATT_REDIRECT_URI=http://foundry-oauth-example.heroku.com/users/att/callback
    git push heroku
    heroku open
    
and  then try out the app
