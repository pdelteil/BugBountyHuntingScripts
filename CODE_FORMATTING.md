
### Coding style and formatting

1. Use `[[]]` instead of `[]`

   Examples
   ```
   if [[ "$var" == "example" ]] ; 
   if [[ "$var" == "example" ]] && [[ "$var2" == "example2" ]] ; 
   ```
   
2. Use `then` and `do` in the same line as conditional code

   Examples
   ```
   for i in $(ls); do
   if [[ "$var" == "example" ]]; then
   ```
