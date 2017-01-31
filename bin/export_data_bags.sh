knife block $TF_VAR_env_name

for config in `knife data bag show config`; do
  knife data bag show -F json --secret-file ~/.chef/$TF_VAR_env_name-databag.key config $config > kitchen/data_bags/config/$config.$TF_VAR_env_name.json
done

for user in `knife data bag show users`; do
  knife data bag show -F json users $user > kitchen/data_bags/users/$user.json
done

shasum kitchen/data_bags/config/* kitchen/data_bags/users/* > kitchen/data_bags/shasum.txt

echo 'done!'
