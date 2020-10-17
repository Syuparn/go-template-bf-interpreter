{{- /* NOTE: add `-` not to output verbose spaces and indents */ -}}

{{- /* constants */ -}}

{{- /* looper is used for range block loop */ -}}
{{- /* NOTE: interpreter resources
     Looper length:        16
     memory size:          (len $Looper)^2
     source length limit:  (len $Looper)^3
     counter in each byte: (len $Looper)^2 (, which is 256)
*/ -}}
{{- $Looper := (index .items 0).metadata.annotations -}}

{{- /* brainf*ck source */ -}}
{{- $Source := (index .items 0).metadata.annotations.src  -}}

{{- /* stdin string for bf interpreter */ -}}
{{- $Stdin := (index .items 0).metadata.annotations.input  -}}

{{- /* variables */ -}}

{{- /* initalize memory ((len $Looper)^2 bytes filled with 0) */ -}}
{{- $memory := "" -}}
{{- range $Looper -}}
    {{- range $Looper -}}
        {{- $memory = print $memory "\x00" -}}
    {{- end -}}
{{- end -}}

{{- /* NOTE: use string length as uint to substitute string concatination/slicing for add/sub */ -}}

{{- /* initialize memory pointer (use length as ptr address) */ -}}
{{- $memoryPtr := "" -}}

{{- /* initialize position in source code where parser reads (use length as position) */ -}}
{{- $parsingBytePos := "" -}}

{{- /* initialize position in stdin to read (use length as position) */ -}}
{{- $readingStdinBytePos := "" -}}


{{- /* run interpreter */ -}}
{{- /* NOTE: write processes directly in loop because variables cannot be resolved in template */ -}}

{{- range $Looper -}}
    {{- range $Looper -}}
        {{- range $Looper -}}
            {{- /* NOTE: exists is implemented only in k8s parser */ -}}
            {{- if exists $Source (len $parsingBytePos) -}}
                {{- $tokenByte := index $Source (len $parsingBytePos) -}}
                {{- $token := printf "%c" $tokenByte -}}

                {{- if eq $token ">" -}}
                    {{- /* increment ptr (or do nothing if ptr reaches max limit) */ -}}
                    {{if exists $memory (len $memoryPtr)}}
                        {{- $memoryPtr =  print $memoryPtr " " -}}
                    {{- end -}}

                {{- else if eq $token "<" -}}
                    {{- /* decrement ptr (or do nothing if ptr reaches min limit)  */ -}}
                    {{- $memoryPtr =  slice $memoryPtr 1 -}}

                {{- else if eq $token "+" -}}
                    {{- /* increment value referred by memoryPtr */ -}}
                    {{- $currentValue := index $memory (len $memoryPtr) -}}
                    {{- $incrementedValue := 0 -}}
                    {{- if eq $currentValue 255 -}}
                        {{- $incrementedValue = 0 -}}
                    {{- else if eq $currentValue 0 -}}
                        {{- $incrementedValue = 1 -}}
                    {{- else -}}
                        {{- /* len $valueLengthStr == $currentValue */ -}}
                        {{- $valueLengthStr := printf (print "%0" $currentValue "d") 0 -}}
                        {{- $incrementedValue = len (print $valueLengthStr " ") -}}
                    {{- end -}}

                    {{- /* replace only referred byte */ -}}
                    {{- $former := slice $memory 0 (len $memoryPtr) -}}
                    {{- $latter := slice $memory (len (print $memoryPtr " ")) -}}
                    {{- $memory = print $former (printf "%c" $incrementedValue) $latter -}}

                {{- else if eq $token "-" -}}
                    {{- /* decrement value referred by memoryPtr */ -}}
                    {{- $currentValue := index $memory (len $memoryPtr) -}}
                    {{- $decrementedValue := 0 -}}
                    {{- if eq $currentValue 0 -}}
                        {{- $decrementedValue = 255 -}}
                    {{- else -}}
                        {{- /* len $valueLengthStr == $currentValue */ -}}
                        {{- $valueLengthStr := printf (print "%0" $currentValue "d") 0 -}}
                        {{- $decrementedValue = len (slice $valueLengthStr 1) -}}
                    {{- end -}}

                    {{- /* replace only referred byte */ -}}
                    {{- $former := slice $memory 0 (len $memoryPtr) -}}
                    {{- $latter := slice $memory (len (print $memoryPtr " ")) -}}
                    {{- $memory = print $former (printf "%c" $decrementedValue) $latter -}}

                {{- else if eq $token "." -}}
                    {{- /* output value referred by memoryPtr */ -}}
                    {{- printf "%c" (index $memory (len $memoryPtr)) -}}

                {{- else if eq $token "," -}}
                    {{- /* copy byte in stdin to address memoryPtr refers */ -}}
                    {{- if exists $Stdin (len $readingStdinBytePos) -}}
                        {{- $stdinByte := index $Stdin (len $readingStdinBytePos) -}}
                        {{- /* replace only referred byte */ -}}
                        {{- $former := slice $memory 0 (len $memoryPtr) -}}
                        {{- $latter := slice $memory (len (print $memoryPtr " ")) -}}
                        {{- $memory = print $former (printf "%c" $stdinByte) $latter -}}
                    {{- end -}}

                {{- else if eq $token "[" -}}
                    {{- /* preceed parsingBytePos to next "]" if value referred by memeoryPtr is 0 */ -}}
                    {{- $currentValue := index $memory (len $memoryPtr) -}}
                    {{- if eq $currentValue 0 -}}
                        {{- range $Looper -}}
                            {{- range $Looper -}}
                                {{- if or (ne $token "]") (exists $Source (len (print $parsingBytePos " "))) -}}
                                    {{- /* increment parsingBytePos */ -}}
                                    {{- $parsingBytePos = print $parsingBytePos " " -}}
                                    {{- /* update token */ -}}
                                    {{- $tokenByte = index $Source (len $parsingBytePos) -}}
                                    {{- $token = printf "%c" $tokenByte -}}
                                {{- end -}}
                            {{- end -}}
                        {{- end -}}
                    {{- end -}}

                {{- else if eq $token "]" -}}
                    {{- /* get parsingBytePos back to last `[` if value referred by memeoryPtr is not 0 */ -}}
                    {{- $currentValue := index $memory (len $memoryPtr) -}}
                    {{- if ne $currentValue 0 -}}
                        {{- range $Looper -}}
                            {{- range $Looper -}}
                                {{- if or (ne $token "[") (lt (len $parsingBytePos) 0) -}}
                                    {{- /* decrement parsingBytePos */ -}}
                                    {{- $parsingBytePos = slice $parsingBytePos 1 -}}
                                    {{- /* update token */ -}}
                                    {{- $tokenByte = index $Source (len $parsingBytePos) -}}
                                    {{- $token = printf "%c" $tokenByte -}}
                                {{- end -}}
                            {{- end -}}
                        {{- end -}}
                    {{- end -}}
                {{- end -}}

                {{- /* increment pos */ -}}
                {{- $parsingBytePos = print $parsingBytePos " " -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
