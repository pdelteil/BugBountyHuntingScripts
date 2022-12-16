
### Coding style and formatting

1. Use `[[]]` instead of `[]`

   Examples
   ```
   if [[ "$var" == "example" ]]; then
      ...code...
      ...more code...
   fi
   if [[ "$var" == "example" ]] && [[ "$var2" == "example2" ]]; then
      ...code...
      ...more code...
   fi
   ```
   
2. Use `then` and `do` in the same line as conditional code

   Examples
   ```
   for i in $(ls); do
      ...code...
      ...more code...
   done
   if [[ "$var" == "example" ]]; then
      ...code...
      ...more code...
   fi
   ```
  
3. Use variables with double quotes

   Examples
   ```
   variable=$(ls -la /tmp)
   echo "content of /tmp folder: $variable"
   #other example
   echo "$variable"
   ```
4. Use indentation (4 spaces)

   Examples
   ```
   function example()
   {
      if [[ "$var" == "example" ]]; then
         ...code...
         if [[ "$var" == "anotherexample" ]]; then
            ...more code...
         fi
      fi
      echo "end"
   }
   ``` 
   
 Loosely based on https://google.github.io/styleguide/shellguide.html
