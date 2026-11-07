// Stable per-account IDs make importing the same cloud record safe on two devices.
async function legacyEntries(value,userId){
  const result=[];const seen=new Set();let skipped=0;
  for(const kind of ['tasks','events','items']){
    const source=Array.isArray(value?.[kind])?value[kind]:[];
    for(let index=0;index<source.length;index++){
      const item=source[index];
      if(!item||typeof item.text!=='string'||!item.text.trim()||item.text.trim().length>120){skipped++;continue}
      const date=kind==='events'?item.date:null;
      if(kind==='events'&&(!/^\d{4}-\d{2}-\d{2}$/.test(date||'')||!Number.isFinite(Date.parse(date))||new Date(date).toISOString().slice(0,10)!==date)){skipped++;continue}
      const identity=item.id??('index:'+index+':'+item.text);
      const bytes=new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(JSON.stringify(['ordiva-import-v1',userId,kind,identity]))));
      bytes[6]=(bytes[6]&15)|80;bytes[8]=(bytes[8]&63)|128;
      const h=Array.from(bytes.slice(0,16),b=>b.toString(16).padStart(2,'0')).join('');
      const id=`${h.slice(0,8)}-${h.slice(8,12)}-${h.slice(12,16)}-${h.slice(16,20)}-${h.slice(20)}`;
      if(seen.has(id))continue;seen.add(id);
      result.push({id,user_id:userId,space_id:null,kind,text:item.text.trim(),done:item.done===true,date});
    }
  }
  return {entries:result,skipped};
}
