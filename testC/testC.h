#ifndef __TESTC_H__
#define __TESTC_H__

#ifdef TESTC_EXPORTS
	#ifdef _MSC_VER
		#define TESTC_API	__declspec(dllexport)
	#else /* Linux */
		#define TESTC_API	__attribute__ ((visibility ("default")))
	#endif /* _MSC_VER */
#else
	#ifdef _MSC_VER
		#define TESTC_API	__declspec(dllimport)
	#else /* Linux */
		#define TESTC_API
	#endif /* _MSC_VER */
#endif /* TESTC_EXPORTS */

TESTC_API void PrintHelloWorldArchive(void);

#endif /* __TESTC_H__ */
