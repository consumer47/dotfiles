   #!/bin/sh

   TMP_ALL_URLS=/tmp/tmux_urls
   TMP_ONLY_URLS=/tmp/tmux_urls_filtered
   DEBUG_LOG=/tmp/urlview_debug.log

   : > $DEBUG_LOG

   # Capture the entire scrollback history
   tmux capture-pane -J -p > $TMP_ALL_URLS
   echo "Captured pane content (including history):" >> $DEBUG_LOG
   cat $TMP_ALL_URLS >> $DEBUG_LOG
   echo "--------------------" >> $DEBUG_LOG

   grep -Eo 'http[s]?://[^ ]+' $TMP_ALL_URLS > $TMP_ONLY_URLS
   echo "Filtered URLs:" >> $DEBUG_LOG
   cat $TMP_ONLY_URLS >> $DEBUG_LOG
   echo "--------------------" >> $DEBUG_LOG

   if [ -s $TMP_ONLY_URLS ]; then
       echo "Filtered URLs found" >> $DEBUG_LOG
       tmux display-message "Filtered URLs found"
   else
       echo "No URLs found" >> $DEBUG_LOG
       tmux display-message "No URLs found"
   fi
