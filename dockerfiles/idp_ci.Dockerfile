FROM ruby:3.0.3

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update -qq
RUN apt-get install -y --no-install-recommends nodejs \
      locales \
      google-chrome-stable \
      yarn

RUN curl -Ss "https://chromedriver.storage.googleapis.com/$(curl -Ss "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$(google-chrome --version | grep -Po '\d+\.\d+\.\d+' | tr -d '\n')")/chromedriver_linux64.zip" > /tmp/chromedriver.zip
RUN unzip /tmp/chromedriver.zip -d /tmp/chromedriver
RUN mv -f /tmp/chromedriver/chromedriver /usr/local/bin/chromedriver
RUN rm /tmp/chromedriver.zip
RUN rmdir /tmp/chromedriver
